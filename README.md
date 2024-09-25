CPU Experiment 2023 - Group 6 Core
=
## Summary
RISC-V based 5-stage pipeline processor core with the following features.
1. FPU (fadd, fmul, etc.) Pipeline: Allowed write-back to memory and registers even before previous FPU instructions complete, handling data dependency and varying latencies of different FPU operations.
2. Tournament Branch Prediction: Acheived 80% precision by leveraging both global and local branch histories.
3. Dedicated BRAM for Low Address Range: Loaded floating point immediate values and global variables without lwStall, enabling data reads between Execute and Memory stages.

You can see the additional superschalar implementation in the `superschalar` branch. 

## Slide
https://docs.google.com/presentation/d/1-QYyPGRGEIJhunH3_CakvjWo_-eKDOzxqOhcFEfTnUY
## File Structure
```
|- core                         # Core-related files
|- io                           # I/O-related files
|- FPU-Memory                   # Omitted for brevity
|- vivado                       # Files for Vivado implementation
    |- top.sv                   # Top module
    |- Nexys-A7-100T-Master.xdc # Constraint file
|- test                         # Files for running with Verilator
```
## Results
- Operates at 93.75 MHz without any negative slack.
- 256x256 ray tracing: Completed in 57.7 seconds with an IPC (Instructions Per Cycle) of 0.64.
