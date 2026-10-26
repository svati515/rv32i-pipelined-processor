# 32-bit 5-Stage Pipelined RISC-V RV32I Processor

## Project Overview

This project focuses on the RTL design and simulation of a 32-bit RISC-V RV32I processor using Verilog HDL. It explores a five-stage instruction pipeline and techniques for handling data hazards.

## Key Features

- 32-bit RISC-V processor architecture
- Five-stage pipeline: IF, ID, EX, MEM and WB
- Data forwarding for handling data dependencies
- Hazard detection logic
- Modular Verilog HDL design
- RTL simulation and waveform analysis using Xilinx ISE tools

## Pipeline Architecture

1. **IF – Instruction Fetch:** Fetches the instruction from instruction memory.
2. **ID – Instruction Decode:** Decodes the instruction and reads the required registers.
3. **EX – Execute:** Performs ALU operations and calculates addresses.
4. **MEM – Memory Access:** Performs data-memory operations when required.
5. **WB – Write Back:** Writes the result back to the register file.

## Technologies Used

- Verilog HDL
- Xilinx ISE
- RTL simulation and waveform analysis

## Repository Contents

- `PC_.v` – Program counter and/or single-cycle processor-related RTL; confirm the exact contents of this file.
- `Pipelined_RISC_V.v` – Pipelined processor RTL implementation.
- `Risc_V.v` – Processor RTL; inspect the module to confirm whether forwarding and hazard detection are included.

## Project Status

- **RTL Design:** Completed
- **Simulation and Functional Verification:** Reported as completed; simulation evidence can be added to this repository.
- **FPGA Implementation:** Pending
- **Hardware Validation:** Pending

## Contributors

- **Svati Pandey** — Shared project contributor
- **Abhimanyu** — Shared project contributor

Contributor roles should reflect the work each person actually performed.

## Future Improvements

- Expand instruction-level verification.
- Add automated testbenches and test cases.
- Verify forwarding and hazard-detection scenarios.
- Complete FPGA implementation and hardware testing.

