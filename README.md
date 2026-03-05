# Digital-Baseband-Processor-
A complete Digital Baseband Processor designed for wireless communication systems, implementing a full DUC/DDC (Digital Up/Down Conversion) pipeline. The processor takes baseband I/Q samples and performs ×200 interpolation to upconvert signals to 803MHz carrier frequency. 

Baseband I/Q (50MHz)
       ↓
 32-bit NCO with 1024-point sin/cos LUT
       ↓
    Complex IQ Mixer
       ↓
  CIC Interpolator (×20)
       ↓
  CIC Interpolator (×10)
       ↓
 Dual 41-tap CFIR Compensation Filters
       ↓
    10-phase Polyphase FIR
       ↓
    Anti-image FIR
       ↓
 803MHz Carrier Output (×200 total interpolation)

Design Flow & Tools
Front-End Design
Algorithm Validation: MATLAB (IQ handling, CIC droop compensation, polyphase response)

RTL Implementation: Fixed-point Verilog with 48/40-bit precision

Key Features: Pipelined 32-bit complex multipliers, runtime overflow detection

Back-End Implementation
Synthesis: Synopsys Design Compiler

Physical Design: Synopsys IC Compiler II

Timing Analysis: Synopsys PrimeTime

Sign-off: Full GDSII with DRC/LVS verification


<img width="787" height="550" alt="Image" src="https://github.com/user-attachments/assets/142053b1-e576-45c9-93e4-0e319055cb76" />
<img width="787" height="550" alt="Image" src="https://github.com/user-attachments/assets/2e48e028-7051-433c-9492-d591c2b9624d" />
<img width="796" height="488" alt="Image" src="https://github.com/user-attachments/assets/9f7ae359-97ea-4316-924a-2b0864c115a4" />
<img width="685" height="524" alt="Image" src="https://github.com/user-attachments/assets/f38ee531-3a18-48c9-84dd-db5a1360f5f8" />
<img width="666" height="516" alt="Image" src="https://github.com/user-attachments/assets/30e4d012-6df0-4b63-a7bc-5d13ea40d4b9" />
<img width="1569" height="468" alt="Image" src="https://github.com/user-attachments/assets/37dcb331-66f7-4718-8a4f-4367f3230127" />
<img width="1547" height="770" alt="Image" src="https://github.com/user-attachments/assets/d7f8a9d7-23be-4c5e-81ca-8187dc0ba5b2" />

