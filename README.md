# VHDL Cryptographic System

## Introduction

This VHDL project describes an integrated cryptographic system on an FPGA, designed to perform various cryptographic tasks. The system's functionalities include true random number generation, data processing, and performing modular arithmetic operations. It leverages FIFOs (First-In, First-Out) and BRAMs (Block RAMs) to manage the data flow between its different functional modules.

## Key Features

The system is controlled by dedicated enable signals, allowing it to operate in three primary modes:

1.  **Random Seed Generation (`random_enable`)**:
    * Generates random bytes using the `random_seed` module.
    * These random bytes are stored in a small FIFO buffer (`SEEDFIFO`).
    * The generated seed is transmitted out via the UART interface.

2.  **Data Loading and Computation (`f_enable`)**:
    * Receives 8-bit data via the UART interface.
    * Stores the incoming data (2048 bytes) into two separate BRAMs (`f_bram_mem` and `g_bram_mem`).
    * Utilizes the `mq_Add` module to perform a modular addition on 32-bit values, which are derived from the data stored in `f_bram_mem` and `g_bram_mem`.
    * The 32-bit result of this computation is stored in the `h_bram_mem`.

3.  **Verification Mode (`g_enable`)**:
    * Receives data for a verification process via UART.
    * This data is buffered in a large FIFO (`VRFYFIFO`).
    * Controls a dedicated IP core (`design_verify_raw_wrapper`) to execute the verification logic, using the loaded parameters.
    * Transmits the 8-bit verification result back through the UART interface.

## Module Architecture

The project is structured hierarchically, comprising the following main modules:

* **`main_system`**: The top-level entity that orchestrates the data flow and controls the sub-modules.
* **`UART_TOP`**: Manages the serial communication interface, handling both data reception (`rx`) and transmission (`tx`).
* **`ring_buffer`**: A generic FIFO buffer component that is instantiated multiple times to create `FANDGFIFO`, `SEEDFIFO`, and `VRFYFIFO` with different parameters.
* **`random_seed`**: A module responsible for generating random numbers.
* **`mq_Add`**: A module that performs a modular addition operation on 32-bit data.
* **`design_verify_raw_wrapper`**: An IP core (or a synthesized module from a high-level design) that encapsulates the core verification logic.

## How It Works

The data flows through the system in the following sequence:

1.  **Data Ingress**: Data from the UART (`rx`) is processed by `UART_TOP` and directed to either the `FANDGFIFO` or `VRFYFIFO` based on the active mode.
2.  **Storage**: Data from `FANDGFIFO` is written into the simulated BRAMs (`f_bram_mem`, `g_bram_mem`).
3.  **Computation**: Data from the BRAMs is read and fed into the `mq_Add` module for computation. The 32-bit results are then stored in `h_bram_mem`.
4.  **Verification**: Data is loaded into `VRFYFIFO` and passed to `design_verify_raw_wrapper`. The verification module also accesses `h_bram_mem` as part of its operation.
5.  **Data Egress**: The results from either the seed generation (`SEEDFIFO`) or the verification process (`design_verify_raw_wrapper`) are selected by the `UART_TX_Arbiter` and sent out via UART.

## Usage Guide

To synthesize and run this project on an FPGA:

1.  Ensure you have an FPGA development environment (e.g., Vivado, Quartus) installed.
2.  Create a new project and add all relevant VHDL files.
3.  Set `main_system.vhd` as the top-level entity.
4.  Synthesize and implement the bitstream onto your FPGA board.
5.  Use a serial communication tool (e.g., Tera Term, PuTTY) to send commands and data over UART to activate the different modes of the system.

* To start random seed generation, send the byte `x"46"` via UART while `random_enable = '1'`.
* Use `f_enable` and `g_enable` to switch between the data loading/computation and verification modes.

## Author

[Your Name]
[Contact Information, e.g., email or GitHub profile]

---
