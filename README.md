# APB-UART-Receiver
Design of an APB UART Receiver supporting variable data sizes (5, 7, or 8 bits) and programmable bit periods

<img width="793" height="373" alt="image" src="https://github.com/user-attachments/assets/feae8df0-3d2c-403b-9355-2ce1b1063fd1" />

## Overview 
The APB UART receiver integrates an APB Subordinate module with a UART receiver block to process serial data, configure registers, and report status to the master. It supports data sizes of 5, 7, or 8 bit and programmable bit periods. 

## Repo Structure 

The project includes the following SystemVerilog modules:

  - apb_subordinate.sv: Implements the APB interface, managing register reads/writes for configuration (bit period, data size) and status (data ready, errors).
  
  - apb_uart_rx.sv: Top-level module connecting the APB subordinate to the UART receiver block.
  
  - rcv_block.sv: Core UART receiver, coordinating start/stop bit detection, data shifting, and error checking.
  
  - rcu.sv: Receiver Control Unit (RCU) with a finite state machine to manage the UART receiving process.
  
  - timer.sv: Generates timing signals (shift strobe, packet done) based on configurable bit periods and data sizes.
  
  - flex_counter.sv: Parameterized counter for timing and bit counting.
  
  - flex_sr.sv: Parameterized shift register for serial-to-parallel data conversion.
  
  - sr_9bit.sv: 9-bit shift register tailored for UART data with configurable data sizes.

## Design Features

- APB Interface: Supports read/write operations for config registers (bit period, data size) and status registers (error, data ready).

- Configurable UART: Supports 5, 7, or 8 bit data packets with a programmable bit period.

- Error detection: Detects framing errors(invalid stop bit) and overrun errors (new data before reading previous).
  
## Module Overview
- apb_subordinate: Manages APB transactions, mapping addresses to registers:
  
| paddr | Size |  Access  | Description                                                      |
|-------|------|----------|------------------------------------------------------------------|
|   0x0   |  1   |Read Only |Data Status Reg: <br> 0 -> No new data <br>    1 -> New data                         |  
|   0x1   |  1   |Read Only |Error Status Reg: <br> 0 -> No Error <br> 1 -> Framing  <br> 2 -> Overrun  <br> 3 -> Both|
|   0x2   |  2   |Read/Write|Bit period Config Reg                                             |
|   0x4   |  1   |Read/Write|Data Size Config Reg                                              |
|   0x6   |  1   |Read Only |Data Buffer                                                       |

- rcv_block: Top-Level UART reception with submodules:
  
<img width="512" height="499" alt="image" src="https://github.com/user-attachments/assets/eceef10f-3f1c-42d2-ad0a-98171cd8f372" />

    - rcu: FSM controlling start bit detection, data shifting, and stop bit checking.
    
    - sr_9bit: Shifts serial data into a 9-bit register, adjusting for data size.
    
    - timer: Generates timing signals using two flex_counter instances.
    
    - rx_data_buff: Buffers received data and tracks overrun errors.
    
    - start_bit_det & stop_bit_chk: Detect start/stop bits and flag framing errors. 
    
    - flex_counter & flex_sr: Parameterized modules for reusable counting and shifting logic.
 
## Notes 
- The design assumes a single stop bit and no parity bit.
- The bit_period register is 14 bits, allowing for values of 10 to 16,384, where 10 is the reset value.
- The data_size register supports 5, 7, or 8-bit data; other values default to 8 bits.
- The psaterr signal is asserted for invalid APB write addresses.
