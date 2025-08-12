`timescale 1ns / 10ps

module rcv_block (
    input logic clk,
    input logic n_rst,
    input logic serial_in,
    input logic data_read,
    input logic [3:0] data_size,
    input logic [13:0] bit_period,
    output logic [7:0] rx_data,
    output logic data_ready,
    output logic overrun_error,
    output logic framing_error
);

logic new_packet_detected, packet_done, sbc_clear, sbc_enable, load_buffer, enable_timer, shift_strobe;
logic [7:0] packet_data;
logic stop_bit;

rcu rcu0 (.clk(clk), .n_rst(n_rst), .new_packet_detected(new_packet_detected), .packet_done(packet_done), .framing_error(framing_error), .sbc_clear(sbc_clear), .sbc_enable(sbc_enable), .load_buffer(load_buffer), .enable_timer(enable_timer));

sr_9bit sr0 (.clk(clk), .n_rst(n_rst), .shift_strobe(shift_strobe), .serial_in(serial_in), .packet_data(packet_data), .stop_bit(stop_bit), .data_size(data_size));

timer t0 (.clk(clk), .n_rst(n_rst), .enable_timer(enable_timer), .data_size(data_size), .bit_period(bit_period), .shift_strobe(shift_strobe), .packet_done(packet_done));

rx_data_buff rx0 (.clk(clk), .n_rst(n_rst), .load_buffer(load_buffer), .packet_data(packet_data), .data_read(data_read), .rx_data(rx_data), .data_ready(data_ready), .overrun_error(overrun_error));

start_bit_det srt0 (.clk(clk), .n_rst(n_rst), .serial_in(serial_in), .new_packet_detected(new_packet_detected));

stop_bit_chk stp0 (.clk(clk), .n_rst(n_rst), .sbc_clear(sbc_clear), .sbc_enable(sbc_enable), .stop_bit(stop_bit), .framing_error(framing_error));

endmodule

