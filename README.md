<div align="center">

# ⚡ Spartan-6 DSP48A1 Slice — RTL Design & Verification

### A synthesizable Verilog model of the Xilinx Spartan-6 `DSP48A1` slice, with a self-checking testbench and an automated QuestaSim simulation flow.

</div>

This repository provides a complete **RTL design, FPGA implementation, and functional verification** of the **`DSP48A1`** arithmetic slice embedded in the **Xilinx Spartan-6** FPGA fabric. The design is captured in parameterized **Verilog** and faithfully reproduces the slice's datapath — the **pre-adder/subtracter**, **18×18 signed multiplier**, and **48-bit post-adder/subtracter/accumulator** — together with the configurable pipeline registers, `OPMODE`-driven operand multiplexers, and dedicated `BCOUT`/`PCOUT` cascade paths that make the slice suitable for high-throughput DSP applications (FIR filters, MACs, and wide arithmetic).

Verification is performed in **QuestaSim/ModelSim** using a **self-checking testbench** that instantiates two DUT configurations — synchronous and asynchronous reset — to validate reset, clock-enable, and arithmetic behavior. Synthesis and implementation are targeted with **Xilinx Vivado**.

![DSP48A1 Block Diagram](https://github.com/user-attachments/assets/2ca09e32-0752-4066-9980-10da3fc28b73)

---

## 🏷️ Badges

![Verilog](https://img.shields.io/badge/HDL-Verilog-blue?style=for-the-badge&logo=v&logoColor=white)
![FPGA](https://img.shields.io/badge/Target-Spartan--6%20FPGA-orange?style=for-the-badge)
![Vivado](https://img.shields.io/badge/Synthesis-Xilinx%20Vivado-cc0000?style=for-the-badge&logo=xilinx&logoColor=white)
![QuestaSim](https://img.shields.io/badge/Simulation-QuestaSim%20%2F%20ModelSim-00b050?style=for-the-badge)
![Verification](https://img.shields.io/badge/Verification-Self--Checking%20TB-9cf?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Verified-brightgreen?style=for-the-badge)

---

## ✨ Features & Architecture

The `DSP48A1` slice is a high-performance, cascadable arithmetic block. This implementation models its full datapath and configurability:

| Stage | Capability |
| :--- | :--- |
| **Pre-Adder / Subtracter** | Computes `D ± B` ahead of the multiplier (symmetric-FIR optimization), selected by `OPMODE[6]`/`OPMODE[4]`. |
| **18 × 18 Multiplier** | Signed `A1 × B1` product feeding the 36-bit `M` register / output. |
| **X & Z Operand Muxes** | `OPMODE[1:0]` selects the X operand (`0`, `M`, `P`, concatenated `D:A:B`); `OPMODE[3:0]` selects the Z operand (`0`, `PCIN`, `P`, `C`). |
| **Post-Adder / Subtracter** | 48-bit `Z ± (X + CIN)` accumulate path, driven by `OPMODE[7]`, producing `P`, `CARRYOUT`, and `CARRYOUTF`. |
| **Cascade Ports** | Dedicated `BCIN`/`BCOUT` and `PCIN`/`PCOUT` paths for building wide, multi-slice DSP chains. |
| **Configurable Pipeline** | Independently bypassable registers (`A0REG`, `A1REG`, `B0REG`, `B1REG`, `CREG`, `DREG`, `MREG`, `PREG`, `CARRYINREG`, `CARRYOUTREG`, `OPMODEREG`) via the `reg_mux` primitive. |
| **Parameterization** | `CARRYINSEL` (`OPMODE5`/`CARRYIN`), `B_INPUT` (`DIRECT`/`CASCADE`), and `RSTTYPE` (`SYNC`/`ASYNC`). |

**Design highlights**
- 🔧 **Fully parameterized** — every pipeline register and control path is compile-time configurable.
- 🔁 **`reg_mux` primitive** — a reusable register-plus-bypass-multiplexer that cleanly models the slice's optional pipeline stages.
- ✅ **Self-checking verification** — reset and clock-enable integrity are asserted automatically with pass/fail reporting.

---

## 📂 Repository File Structure

```text
Spartan6---DSP48A1/
├── DSP.v                              # Top-level RTL: DSP48A1 slice (module firstDSP)
├── MUX.v                              # reg_mux — configurable pipeline register / bypass mux
├── DSP_tb.v                           # Self-checking testbench (module firstDSP_tb)
├── run.do                             # QuestaSim/ModelSim automation macro (waves + run)
├── Ahmed_Saad_Sweffi_Project_1.pdf    # Detailed design report, synthesis & implementation results
└── README.md                          # Project documentation (this file)
```

---

## 🛠️ Prerequisites

To simulate, synthesize, and implement this design, the following EDA tools are recommended:

| Tool | Purpose |
| :--- | :--- |
| **Siemens QuestaSim / ModelSim** | RTL functional simulation & waveform analysis |
| **Xilinx Vivado** | Synthesis & implementation targeting the Spartan-6 architecture |
| **Verilog-2001** compliant simulator | Required language support for the RTL and testbench |

---

## 🧪 Simulation & Verification

The design ships with an automated simulation flow driven by the `run.do` macro, which compiles nothing on its own — it assumes the design library is already built, then loads the testbench, adds all relevant signals to the wave window, and runs to completion.

### Option A — One-command flow (recommended)

From the QuestaSim/ModelSim console, compile the sources and launch the macro:

```tcl
# 1) Create and map the working library
vlib work
vmap work work

# 2) Compile the RTL and testbench
vlog MUX.v DSP.v DSP_tb.v

# 3) Run the automated simulation macro (elaborate + waves + run -all)
do run.do
```

### Option B — Batch / command-line

```bash
vlib work
vlog MUX.v DSP.v DSP_tb.v
vsim -c -do run.do
```

### What `run.do` does
1. Elaborates the testbench: `vsim -voptargs=+acc work.firstDSP_tb`.
2. Adds all stimulus, control, and observed signals to the **Wave** window.
3. Executes `run -all` to complete the full stimulus sequence.

### Expected results
The self-checking testbench validates three phases and prints its verdict to the transcript:

```text
RESET TEST PASSED
CLOCK ENABLE TEST PASSED
```

- **Reset test** — confirms all internal pipeline registers clear correctly for both **SYNC** (`dut`) and **ASYNC** (`dut_2`) configurations.
- **Clock-enable test** — verifies registers hold state when clock enables are deasserted.
- **Functional test** — exercises directed `OPMODE` patterns across the pre-adder, multiplier, and post-adder/accumulate paths, observable in the waveform.

> ℹ️ If either integrity check fails, the testbench reports the failing stage (e.g., `Error in SYNCH RESET functionality`) and halts via `$stop`.

---

## 📄 Documentation

A comprehensive project report is included as **[`Ahmed_Saad_Sweffi_Project_1.pdf`](./Ahmed_Saad_Sweffi_Project_1.pdf)**. It covers:

- Detailed micro-architecture and datapath analysis of the `DSP48A1` slice.
- `OPMODE` encoding and operand-mux selection tables.
- **Xilinx Vivado synthesis and implementation reports** (resource utilization, schematic, and timing).
- Verification strategy and simulation waveform results.

---

<div align="center">

### 👨‍💻 Author

**Done by me — Ahmed Saad Sweffi**

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Ahmed%20Saad%20Sweffi-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/ahmed-saad-sweffi-09b2751a9)

*Digital Design & Verification Engineer — RTL • FPGA • VLSI*

</div>
