# Digital Up-Converter (DUC) RTL Design in Verilog

> A fully pipelined, IQ-based Digital Up-Converter (DUC) implemented in synthesisable Verilog.  
> Designed from first principles algorithm verified in MATLAB before a single line of RTL was written.

---

## Table of Contents

1. [What Is a DUC and Why Does It Matter?](#1-what-is-a-duc-and-why-does-it-matter)
2. [System Overview](#2-system-overview)
3. [Signal Flow End to End](#3-signal-flow--end-to-end)
4. [Module-by-Module Deep Dive](#4-module-by-module-deep-dive)
5. [Bit-Width Growth Across the Chain](#5-bit-width-growth-across-the-chain)
6. [MATLAB Pre-Verification](#6-matlab-pre-verification)
7. [RTL Simulation Results](#7-rtl-simulation-results)
8. [File Structure](#8-file-structure)
9. [How to Simulate](#9-how-to-simulate)
10. [Design Decisions & Trade-offs](#10-design-decisions--trade-offs)
11. [Real-World Applications](#11-real-world-applications)
12. [What I Learned](#12-what-i-learned)

---

## 1. What Is a DUC and Why Does It Matter?

In any wireless communication system, a baseband signal (the actual information voice, data, video) must be translated to a much higher radio frequency before it can be transmitted over the air. This translation process is called **up-conversion**.

A **Digital Up-Converter (DUC)** does this entirely in the digital domain, using an FPGA or ASIC, before the signal ever reaches a DAC. This is the approach used in modern **Software-Defined Radios (SDR)**, **5G base stations**, **radar systems**, and **satellite communication** hardware.

The DUC has two main jobs:
1. **Interpolation** : increase the sample rate from the slow baseband rate up to the fast RF rate.
2. **Frequency translation** : shift the baseband signal from 0 Hz to a target carrier frequency using an NCO (Numerically Controlled Oscillator) and mixer.

This project implements a complete, 8-stage DUC pipeline capable of taking 8-bit IQ baseband samples and producing 28-bit IQ output at a much higher sample rate, centred around a 30 MHz carrier all in synthesisable Verilog RTL.

---

## 2. System Overview

```
 Baseband IQ Input (8-bit, low rate)
          │
          ▼
 ┌─────────────────┐
 │ S1: Input Pre-  │  Clamp I/Q to valid signed 8-bit range
 │    Processor    │
 └────────┬────────┘
          │ 8-bit IQ
          ▼
 ┌─────────────────┐
 │ S2: CIC ×5      │  Interpolate by 5 (3-stage CIC filter)
 │  Interpolator   │  8-bit → 16-bit, rate ×5
 └────────┬────────┘
          │ 16-bit IQ
          ▼
 ┌─────────────────┐
 │ S3: CFIR        │  Compensating FIR — corrects CIC droop
 │ (11-tap FIR)    │  16-bit → 19-bit
 └────────┬────────┘
          │ 19-bit IQ
          ▼
 ┌─────────────────┐
 │ S4: CIC ×5      │  Second interpolation stage by 5
 │ Interpolator 2  │  19-bit → 21-bit, rate ×5
 └────────┬────────┘
          │ 21-bit IQ
          ▼
 ┌─────────────────┐
 │ S5: PFIR        │  Pulse-shaping FIR (32-tap symmetric)
 │ (Pulse Shaping) │  21-bit → 24-bit
 └────────┬────────┘
          │ 24-bit IQ
          ▼
 ┌─────────────────┐
 │ S6: Polyphase   │  Polyphase FIR — interpolate by 10
 │     FIR (×10)   │  24-bit → 28-bit
 └────────┬────────┘
          │ 28-bit IQ
          ▼
 ┌─────────────────┐
 │ S7: Anti-Image  │  Suppress interpolation images
 │     FIR         │  28-bit → 28-bit
 └────────┬────────┘
          │ 28-bit IQ
          ▼
 ┌─────────────────┐
 │ S8: NCO + Mixer │  Frequency translation to 30 MHz carrier
 │ (3-stage pipe)  │  28-bit → 28-bit IQ output
 └────────┬────────┘
          │
 RF-rate IQ Output (28-bit, high rate)
```

**Total interpolation ratio: 5 × 5 × 10 = 250×**

---

## 3. Signal Flow — End to End

| Stage | Module | Function | Input Width | Output Width | Rate Change |
|-------|--------|---       |---          |---           |---          |
| S1 | `input_preprocessor` | Clamp & validate IQ | 8-bit | 8-bit | ×1 |
| S2 | `cic_interpolator_x5` | CIC interpolation | 8-bit | 16-bit | ×5 |
| S3 | `CFIR` | CIC droop compensation | 16-bit | 19-bit | ×1 |
| S4 | `CIC_Interpolator_Stage2` | CIC interpolation | 19-bit | 21-bit | ×5 |
| S5 | `PFIR_Filter` | Pulse shaping (32-tap symmetric) | 21-bit | 24-bit | ×1 |
| S6 | `Polyphase_FIR` | Polyphase interpolation | 24-bit | 28-bit | ×10 |
| S7 | `AntiImage_FIR` | Anti-imaging filter | 28-bit | 28-bit | ×1 |
| S8 | `NCO_Mixer` | IQ frequency up-conversion | 28-bit | 28-bit | ×1 |

All modules are chained using a `valid_in / valid_out` handshake protocol, so backpressure and data-valid gating work cleanly through the full pipeline.

---

## 4. Module-by-Module Deep Dive

### S1 : `input_preprocessor.v`

Before data enters the DSP chain, it is clamped to the valid signed 8-bit range [−128, +127]. This prevents overflow at the very first stage. The module is fully synchronous, with a registered output and a `data_out_valid` flag.

**Key design choice:** Clamping is done using signed comparisons (`$signed`) to handle two's complement correctly a subtle but important RTL detail.

---

### S2 : `cic_interpolator_x5.v`

A 3-stage **Cascaded Integrator-Comb (CIC)** filter with interpolation factor R=5.

CIC filters are extremely hardware-efficient for large rate changes they use only adders and registers, no multipliers. The structure is:

- **Integrators** operate at the low (input) sample rate
- **Upsampler** inserts zeros to raise the rate by 5×
- **Comb sections** operate at the high (output) rate

**Bit growth:** The CIC filter grows word width naturally. With N=3 stages and R=5, the maximum bit growth is N × log2(R) ≈ 7 bits. The output is 16-bit with a right-shift of 7 to compensate for the CIC passband gain.

---

### S3 : `CFIR.v`

CIC filters have a non-flat passband they droop (attenuate) at higher frequencies. The **Compensating FIR (CFIR)** corrects this droop.

This is an 11-tap linear-phase FIR with symmetric coefficients:

```
h = [10, 15, 25, 40, 65, 70, 65, 40, 25, 15, 10]
```

The MAC (multiply-accumulate) accumulator is 30 bits wide internally, then right-shifted by 11 bits (Q11 scaling) to produce a clean 19-bit output. The delay line shifts on every valid clock cycle.

---

### S4 : `CIC_Interpolator_Stage2.v` (cic_interpolator_2.v)

A second 3-stage CIC interpolator, this time operating on 19-bit input and producing 21-bit output with R=5. 

The internal processing width is 28 bits to prevent overflow during accumulation. The final output is scaled back to 21 bits using a 7-bit arithmetic right shift.

**Why two CIC stages?** Breaking the interpolation into two ×5 stages (instead of one ×25) is much more area-efficient and reduces the quantisation noise accumulated in a single large CIC.

---

### S5 : `PFIR_Filter.v` (Pulse_shaping_FIR.v)

A 32-tap **symmetric linear-phase FIR** used for pulse shaping. Pulse shaping controls the bandwidth of the transmitted signal and limits inter-symbol interference (ISI).

**Hardware optimisation:** Because the filter is symmetric (h[k] = h[31−k]), the design pre-adds symmetric sample pairs before multiplying:

```
sum += h[k] * (delay[k] + delay[31-k])
```

This halves the number of multiplications required from 32 to 16. This is a standard RTL optimisation for linear-phase FIR filters.

The output uses a 2-stage pipeline (MAC register → scale register → output register) to improve timing closure.

---

### S6 : `Polyphase_FIR.v` (PFIR.v)

A **polyphase FIR** with interpolation factor R=10, using 8 taps per polyphase branch (80 coefficients total).

**What is a polyphase filter?** Instead of computing a full 80-tap FIR and throwing away 9 out of every 10 outputs (which would be wasteful), the polyphase structure splits the filter into 10 sub-filters (called phases). For each input sample, it computes all 10 outputs sequentially, one phase at a time, cycling through `phase_counter` from 0 to 9.

This is the most computationally efficient way to do large-ratio interpolation with FIR filtering combined. A `phase_counter` register and an `active` flag control output sequencing.

---

### S7 : `Anti_image.v`

After interpolation, spectral images appear at multiples of the original sample rate. The **Anti-Image FIR** is a 10-tap lowpass filter that suppresses these images before the signal reaches the NCO mixer.

Coefficients are in Q13 fixed-point format. The filter uses a 3-stage output pipeline (MAC → scale → output) to ensure timing closure at high clock rates.

Synthesis attributes `(* syn_preserve = 1 *)` and `(* keep = "true" *)` are applied to the delay lines to prevent the synthesiser from optimising them away.

---

### S8 : `NCO_MIXER.v`

The final stage: a fully pipelined **Numerically Controlled Oscillator (NCO) + IQ Mixer**.

**NCO:** A 32-bit phase accumulator increments by a fixed Frequency Tuning Word (FTW) every valid clock cycle. The 10 MSBs of the phase address a 1024-entry sine/cosine LUT stored in memory files (`cos_lut.mem`, `sine_lut.mem`).

**FTW calculation for 30 MHz at 100 MHz clock:**
```
FTW = (f_carrier / f_clock) × 2^32 = (30/100) × 2^32 = 0x4CCCCCCD
```

**Complex mixing (IQ frequency translation):**
```
I_out = I_in × cos(ωt) − Q_in × sin(ωt)
Q_out = I_in × sin(ωt) + Q_in × cos(ωt)
```

The NCO is **valid-gated** — the phase accumulator only advances when `valid_in` is high. This ensures the carrier phase stays perfectly synchronised with the data stream (critical for avoiding phase errors in the output).

**3-stage pipeline:**
1. LUT read + input registration
2. Multiply (four multiplications: I×cos, Q×sin, I×sin, Q×cos)
3. Add/subtract + right-shift by 15 (Q15 scaling)

---

## 5. Bit-Width Growth Across the Chain

One of the most important skills in RTL DSP design is tracking bit growth carefully to avoid overflow or excessive truncation at each stage.

```
S1:  8-bit  →  8-bit   (clamped input)
S2:  8-bit  → 16-bit   (CIC ×5, gain compensated by >>7)
S3: 16-bit  → 19-bit   (CFIR, 30-bit MAC >> 11)
S4: 19-bit  → 21-bit   (CIC ×5 stage 2, 28-bit internal >>7)
S5: 21-bit  → 24-bit   (Pulse-shaping FIR, symmetric MAC >>13)
S6: 24-bit  → 28-bit   (Polyphase FIR ×10, 42-bit MAC >>13)
S7: 28-bit  → 28-bit   (Anti-image FIR, 46-bit MAC >>13)
S8: 28-bit  → 28-bit   (NCO mixer, 44-bit MAC >>15)
```

The signed arithmetic is handled throughout using `$signed()` casts to ensure correct two's complement behaviour in Verilog.

---

## 6. MATLAB Pre-Verification

Before writing any Verilog, the full signal processing chain was modelled and verified in MATLAB. This is an important engineering practice it confirms the algorithm works correctly in floating point before you commit to fixed-point RTL.

**What was verified in MATLAB:**

- A simulated RF input was generated with a 10 kHz baseband signal modulated onto a carrier (visible in the frequency-domain plot below as the two spectral peaks)
- The DDC (Digital Down-Converter) output was used as the reference for the baseband IQ signal fed into the DUC
- The frequency-domain spectra of the original and reconstructed signals were compared and confirmed to match, validating the interpolation and compensation filters

| Plot | What it Shows |
|---|---|
| Original 10 kHz I-Data Segment | Baseband spectrum before up-conversion |
| DDC Output I-Channel (Aligned & Compensated) | Recovered signal spectrum after DDC used as DUC input reference |
| Simulated RF Input (Time & Frequency) | RF signal at ~50 MHz showing the correct carrier placement |

The MATLAB verification confirmed that the filter chain produces spectral peaks at the correct frequencies with the expected magnitude, giving confidence that the Verilog implementation was logically correct before simulation.

---

## 7. RTL Simulation Results

The design was simulated using a Verilog testbench. The waveform below (captured in GTKWave/Vivado) shows:

- `data_i_in_low[7:0]` / `data_q_in_low[7:0]` — 8-bit baseband IQ input samples arriving at the low sample rate
- `valid_in_low` — input valid strobe (active every ~250 clock cycles, reflecting 250× rate difference)
- `data_i_out_high[27:0]` / `data_q_out_high[27:0]` — 28-bit processed IQ output at the high sample rate
- `valid_out_high` — output valid strobe, active at the high output rate
- `low_rate_counter` — internal counter showing the 250× rate relationship
- `output_sample_counter` — tracks the number of valid output samples produced

Key observations from simulation:
- The pipeline correctly produces 250 output samples for every 1 input sample
- Bit-width transitions are clean with no overflow artefacts
- The NCO phase accumulator advances only on valid cycles, maintaining carrier coherence
- Reset behaviour is correct across all 8 pipeline stages

---

## 8. File Structure

```
DUC_Project/
├── rtl/
│   ├── DUC_TOP.v                  # Top-level module (DSP_Top) — chains all 8 stages
│   ├── input_preprocessor.v       # S1: Input clamping and validation
│   ├── cic_interpolator_5.v       # S2: CIC interpolator ×5 (3-stage)
│   ├── CFIR.v                     # S3: CIC compensating FIR (11-tap)
│   ├── cic_interpolator_2.v       # S4: CIC interpolator ×5 (stage 2, 19→21 bit)
│   ├── Pulse_shaping_FIR.v        # S5: Pulse-shaping FIR (32-tap symmetric)
│   ├── PFIR.v                     # S6: Polyphase FIR interpolator ×10
│   ├── Anti_image.v               # S7: Anti-imaging FIR (10-tap)
│   └── NCO_MIXER.v                # S8: NCO + IQ mixer (3-stage pipeline)
├── mem/
│   ├── cos_lut.mem                # 1024-entry cosine LUT (Q15, hex)
│   ├── sine_lut.mem               # 1024-entry sine LUT (Q15, hex)
│   └── sine_1024_lut.mem          # Alternate 1024-entry sine LUT
└── README.md
```

---

## 9. How to Simulate

### Using Icarus Verilog (open-source)

```bash
# Compile all RTL files
iverilog -o duc_sim \
  rtl/DUC_TOP.v \
  rtl/input_preprocessor.v \
  rtl/cic_interpolator_5.v \
  rtl/CFIR.v \
  rtl/cic_interpolator_2.v \
  rtl/Pulse_shaping_FIR.v \
  rtl/PFIR.v \
  rtl/Anti_image.v \
  rtl/NCO_MIXER.v \
  tb/duc_tb.v

# Run simulation
vvp duc_sim

# View waveforms
gtkwave dump.vcd
```

> **Note:** The LUT `.mem` files (`cos_lut.mem`, `sine_lut.mem`) must be in the simulation working directory for the `$readmemh` calls in `NCO_MIXER.v` to succeed.

### Using Vivado (Xilinx)

1. Create a new RTL project
2. Add all `.v` files under `rtl/` as design sources
3. Add `.mem` files as simulation sources (or set the working directory in simulator settings)
4. Add your testbench as a simulation source
5. Run Behavioral Simulation

---

## 10. Design Decisions & Trade-offs

**Why CIC + FIR instead of a single large FIR?**  
A single FIR with 250× interpolation and good stopband rejection would need hundreds of taps and hundreds of multipliers impractical for FPGA. The CIC-CFIR combination achieves the same interpolation with zero multipliers in the CIC, and only a short compensating FIR. This is the industry-standard approach.

**Why two CIC stages (×5 each) instead of one ×25?**  
A single ×25 CIC would require much wider internal registers (bit growth = N × log2(R)), consuming more area. Two ×5 stages keep bit widths manageable and give more control over the filter shape between stages.

**Why a polyphase structure for the final ×10 FIR?**  
Naively computing a ×10 interpolating FIR means computing 80 MAC operations and discarding 9 in every 10 very wasteful. The polyphase decomposition computes each of the 10 output phases directly using only 8 MACs, making it 10× more efficient.

**Why valid-gate the NCO phase accumulator?**  
If the phase accumulator runs freely regardless of valid data, the carrier phase will drift relative to the data whenever the upstream pipeline stalls. By gating on `valid_in`, the NCO advances exactly once per valid data sample — keeping phase coherent with the data.

**Signed arithmetic: using `$signed()` everywhere**  
Verilog defaults to unsigned arithmetic for mixed-width operations. All signal paths use explicit `$signed()` casts to ensure correct two's complement sign extension and arithmetic throughout the chain. Missing even one `$signed()` in a DSP path can introduce subtle but severe distortion bugs.

---

## 11. Real-World Applications

Digital Up-Converters are a fundamental building block in:

| Domain | Application |
|---|---|
| **Wireless Communications** | 4G/5G base station transmitters — multiple carriers are DUC-processed in parallel on one FPGA |
| **Software-Defined Radio (SDR)** | Platforms like USRP, LimeSDR, and AD9361-based boards all use DUC/DDC chains |
| **Radar Systems** | Pulse compression radar uses DUC to generate chirp waveforms at RF rates |
| **Satellite Communications** | Ground station uplinks use DUCs to translate baseband modems to GHz-range signals |
| **Test & Measurement** | Arbitrary waveform generators (AWGs) use DUC chains to synthesise signals up to multi-GHz |
| **Digital Predistortion (DPD)** | Power amplifier DPD systems use DUC to upconvert the correction signal |

---

## 12. What I Learned

This project was my first complete RTL DSP design, built as part of my preparation for a career in RTL/digital design engineering. Here is what it taught me:

- **DSP theory into hardware:** How CIC filters, polyphase decomposition, and compensating FIR filters connect not just as equations but as working RTL structures
- **Fixed-point arithmetic:** Tracking bit growth, choosing shift amounts, and avoiding overflow and underflow across an 8-stage pipeline
- **Valid-handshake design:** Building a pipeline where each stage independently gates its output with a valid flag, rather than relying on a shared global enable this is how real production RTL works
- **Algorithm-first design flow:** Verifying the algorithm in MATLAB before writing RTL saved significant debugging time when the Verilog did not match expectations, it was clear whether the bug was in the algorithm or the implementation
- **RTL debugging discipline:** Reading waveforms systematically at each pipeline stage boundary, rather than only looking at the final output

---

*Designed and implemented by Vineet Dharwadkar — RTL Design Engineer (Fresher)*  
*Tools used: MATLAB (algorithm verification), Verilog HDL (RTL implementation), synopsys VCS / Vivado (simulation)*
Back-End Implementation
Synthesis: Synopsys Design Compiler

Physical Design: Synopsys IC Compiler II

Timing Analysis: Synopsys PrimeTime

Sign-off: Full GDSII with DRC/LVS verification


<img width="787" height="550" alt="Image" src="https://github.com/user-attachments/assets/142053b1-e576-45c9-93e4-0e319055cb76" />
<img width="796" height="488" alt="Image" src="https://github.com/user-attachments/assets/9f7ae359-97ea-4316-924a-2b0864c115a4" />
<img width="685" height="524" alt="Image" src="https://github.com/user-attachments/assets/f38ee531-3a18-48c9-84dd-db5a1360f5f8" />
<img width="666" height="516" alt="Image" src="https://github.com/user-attachments/assets/30e4d012-6df0-4b63-a7bc-5d13ea40d4b9" />
<img width="1569" height="468" alt="Image" src="https://github.com/user-attachments/assets/37dcb331-66f7-4718-8a4f-4367f3230127" />
<img width="1547" height="770" alt="Image" src="https://github.com/user-attachments/assets/d7f8a9d7-23be-4c5e-81ca-8187dc0ba5b2" />

