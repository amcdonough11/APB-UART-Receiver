# APB-UART-Receiver
An **AMBA APB UART receiver** in SystemVerilog with **configurable data size**, **programmable bit period**, and **error detection**. Packaged for easy reuse with **FuseSoC** and set up for one-command simulation + waves.

---
## Summary 
The design integrates an APB subordinate (slave) with a UART receiver block. Software configures **bit period** and **data size** over APB and polls status/data registers to read received bytes. The receiver flags **framing** errors (bad stop bit) and **overrun** (new byte arrives before previous is read).

<p align="center">
  <img src="https://github.com/user-attachments/assets/feae8df0-3d2c-403b-9355-2ce1b1063fd1" alt="top-diagram" width="760">
</p>

---
## Features

| Feature | Description |
|---------|-------------|
| **APB Slave Interface** |  APB compatible, supports standard read/write transactions |
| **Configurable Data Size** | 5, 7, or 8-bit data packets |
| **Programmable Bit Period** | 14-bit register (10 .. 16384 clk cycles), reset = 10 |
| **Error Detection** | Overrun & framing error flags |
| **Status & Control Registers** | APB-readable/writable register map |
| **FuseSoC Support** | Ready for dependency-based build and simulation |
| **Simulation Ready** | Testbenches with waveform outputs |

## What I Did
- Designed and implemented all RTL modules in SystemVerilog **except** `apb_model.sv` (provided as a bus functional model for simulation).
- Created **block diagrams** for the top-level design and **FSM diagrams** for the Receiver Control Unit (RCU) to document architecture and behavior.  
- Wrote **SystemVerilog testbenches** for verification, including:
  - All supported data sizes (5, 7, 8 bits) 
  - Framing Error conditions
  - Overrun Error conditions
  - Variable bit period configurations

## Repo Structure 
```
├─ source/ # SystemVerilog RTL
│ ├─ apb_subordinate.sv # APB register interface
│ ├─ apb_uart_rx.sv # Top-level wrapper (APB <-> UART RX)
│ ├─ rcv_block.sv # UART RX
│ ├─ rcu.sv # Control FSM for receive flow
│ ├─ timer.sv # Bit-period timing, strobes
│ ├─ flex_counter.sv # Param counter
│ ├─ flex_sr.sv # Param shift register
│ ├─ stop_bit_chk.sv # Identifies stop bit
│ ├─ start_bit_det.sv # Identifies start bit
│ ├─ rx_data_buff.sv # Stores UART byte during transaction
│ └─ sr_9bit.sv # 9-bit shift register for 5/7/8 data modes
├─ testbenches/ # SystemVerilog Testbenches
├─ waves/ # Sample VCD/GTKW dump outputs
├─ *.core # FuseSoC core files
├─ Makefile
└─ README.md
```

---

## Module Overview

- **`apb_subordinate.sv`** — APB read/write handling; maps addresses to config/status; asserts `pslverr` on invalid writes  
- **`apb_uart_rx.sv`** — Top-level tying APB to the UART receive path  
- **`rcv_block.sv`** — Start/stop detection, serial-to-parallel, error logic  
- **`rcu.sv`** — FSM: see state transition diagram below  
- **`timer.sv`** — Generates bit-period strobes from the programmable setting
- **`start_bit_det.sv`** — Detects UART start bit and signals the RCU to begin loading
- **`stop_bit_chk.sv`** — Detects UART stop bit and flags framing error
- **`rx_data_buff.sv`** — Stores one byte received from UART transaction and tracks overrun error until master reads buffer
- **`flex_counter.sv` / `flex_sr.sv` / `sr_9bit.sv`** — Reusable parametrized blocks
  
<p align="center">
  <img src="https://github.com/user-attachments/assets/90c02f42-e1f5-49dc-aa5c-9dc886385f3f" alt="rcu-std" width="650">
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/eceef10f-3f1c-42d2-ad0a-98171cd8f372" alt="rcv-block" width="650">
</p>

---
  
## APB Register Map
  
| paddr | Size |  Access  | Description                                                      |
|-------|------|----------|------------------------------------------------------------------|
|   0x0   |  1   |Read Only |**Data Status Reg**: <br> `0` -> No new data <br>    `1` -> New data                         |  
|   0x1   |  1   |Read Only |**Error Status Reg**: <br> `0` -> No Error <br> `1` -> Framing  <br> `2` -> Overrun  <br> `3` -> Both|
|   0x2   |  2   |Read/Write|**Bit period Config Reg** bit time in clk cycles (10..16384); reset `10`       |
|   0x4   |  1   |Read/Write|**Data Size Config Reg**  <br> allowed: <br>`5` bit, <br> `7` bit, <br> `8` bit (others default to 8)|
|   0x6   |  1   |Read Only |**Data Buffer** — received byte                                                   |

- **Invalid write addresses** assert **`PSATERR`** (`PSATERR` → standardized to `pslverr` in docs).
 
---
## APB Bus Signals

| Signal   | Description |
|----------|-------------|
| **PCLK**    | Bus clock signal. |
| **PRESETn** | Active-low bus reset signal. |
| **PADDR**   | Address bus. |
| **PSELx**   | Subordinate (slave) select signal. |
| **PENABLE** | Indicates the transaction is in the data (second) stage. |
| **PWRITE**  | Transaction direction: `0` = read, `1` = write. |
| **PWDATA**  | Data bus for writes to the subordinate. |
| **PRDATA**  | Data bus for reads from the subordinate. |
| **PSATERR** | Active-high error signal from the subordinate. |

- **PREADY** — Not used. UART packets arrive much slower than APB transactions, so stalling the bus is unnecessary. Software polls the status register for new data, allowing other SoC devices to use the bus while UART waits for packets.  
- **PPROT** — Not used. This UART peripheral has no need for varying protection levels during APB transactions.  
- **PSTRB** — Not used. With only 8-bit data buses and single-byte buffering, `PSTRB` would be a fixed 1-bit that always matches `PWRITE`, offering no functional benefit.

---

## Design Notes & Assumptions

- Single stop bit, no parity (simple 8-N-1 style when data size is 8)
- The data size resets to 8, and the bit period resets to 10.
- Payloads of fewer than 8 bits are right align and zero padded.
- Invalid values written to addresses with value restrictions should raise a psaterr and should not modify the
 value at that address.

---

## Verification

**Receiving UART 8'b10101010**
<img width="1000" height="430" alt="image" src="https://github.com/user-attachments/assets/e335e7e1-02ca-4ec7-b8e9-e963e39232d1" />

- Bit period and Data Size reg set to 10 and 8 respectively.
- `new_packet_detected` triggered by falling edge of serial_in
- `shift strobe` samples serial_in in the middle of the sample
- `packet_done` triggered after 8 samples taken 
- 'rx_data' becomes signal receieved from UART and `data_ready` goes high
- APB read of data status reg followed by APB read of data buffer
- `data_read` triggered by read of data buffer and`data_ready` falls to low

**Overrun Error**
<img width="1000" height="430" alt="image" src="https://github.com/user-attachments/assets/2ff37aa4-eda8-4170-b712-4e0c8f0b5fe8" />

- Received 8'b10101010 from first UART transaction (not shown)
- Never read the data buffer as seen by `data_ready` staying high during the second UART transaction
- When second UART transaction finishes, `overrun error` is flagged as first UART transaction has not been read yet
- `rx_data` from first UART transaction is maintained in the data buffer

**Framing Error**
<img width="1000" height="430" alt="image" src="https://github.com/user-attachments/assets/7cf4fe36-7297-4472-aeb6-22abf6d94a5c" />
- Bit period and Data Size reg set to 10 and 5 respectively.
- UART transaction tries to send 8 bit (8'b00000000) over `serial_in`
- The `packet_done` signal triggers on a low, indicating a framing error

## Synthesis Results

**Tool**: Synopsys Design Compiler

**Target Process**: osu05_stdcells (0.5 µm)  

**Target Clock**: 100 MHz (10 ns period)  

**Operating Conditions**: Typical corner, 5 V

| Metric         | Result              | Notes |
|----------------|---------------------|-------|
| **Timing**     | Slack = **+2.49 ns** | Meets timing at 100 MHz |
| **Max Delay**  | 7.42 ns              | Critical path: `bit_period_reg[11] → rollover_flag_reg` |
| **Total Area** | 269,577 units        | From standard cell area report |
| **Power**      | 21.344 mW            | Switching + Internal + Leakage |


