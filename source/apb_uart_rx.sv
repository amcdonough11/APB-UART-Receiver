`timescale 1ns / 10ps

module apb_uart_rx (
    input logic clk,
    input logic n_rst,
    input logic serial_in,
    input logic psel,
    input logic [2:0] paddr,
    input logic penable,
    input logic pwrite,
    input logic [7:0] pwdata,
    output logic [7:0] prdata,
    output logic psaterr
);
 logic [7:0] rx_data;
 logic overrun_error, framing_error, data_read, data_ready;
 logic [13:0] bit_period;
 logic [3:0] data_size;

apb_subordinate sub (.clk(clk), .n_rst(n_rst), .rx_data(rx_data),
.data_ready(data_ready), .overrun_error(overrun_error), .framing_error(framing_error), 
.psel(psel), .paddr(paddr), .penable(penable), .pwrite(pwrite), .pwdata(pwdata), 
.data_read(data_read), .prdata(prdata), .psaterr(psaterr), .data_size(data_size), .bit_period(bit_period));

rcv_block rcv (.clk(clk), .n_rst(n_rst), .serial_in(serial_in), .data_read(data_read), .data_size(data_size), 
.bit_period(bit_period), .rx_data(rx_data), .data_ready(data_ready), .overrun_error(overrun_error), .framing_error(framing_error)); 


endmodule

