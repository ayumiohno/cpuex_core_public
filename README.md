CPU Experiment 2023 - Group 6 Core
=
## Superscalar Implementation
- Fetched two instructions simultaneously.
- Parallelized decode, execute, and writeback stages.
- Merged operations in the memory stage.
- Core implementations located in `core/core.sv`, `core/memory_reg.sv`, and `core/two_line_fifo.sv`.
- Due to bottlenecks in data dependency, memory access, and hardware frequency, we opted for a non-superscalar implementation (on the main branch) for performance measurements.
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
