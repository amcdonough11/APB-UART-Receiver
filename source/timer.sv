`timescale 1ns / 10ps

module timer (
    input logic clk, 
    input logic n_rst,
    input logic enable_timer,
    input logic [3:0] data_size,
    input logic [13:0] bit_period,
    output logic shift_strobe,
    output logic packet_done
);

    /*logic [3:0] count_out, count_out2;
    logic bit_count_done;

    flex_counter clock_count (.clk(clk), .n_rst(n_rst), .clear(1'b0),.count_enable(enable_timer), .rollover_val(4'd10), .rollover_flag(shift_strobe), .count_out(count_out));
    flex_counter bit_count (.clk(clk), .n_rst(n_rst), .clear(1'b0),.count_enable(count_out == 5), .rollover_val(4'd9), .rollover_flag(bit_count_done), .count_out(count_out2));

    assign packet_done = bit_count_done && shift_strobe;*/

    logic [13:0] clock_count;
    logic bit_count_done;
    logic [3:0] bit_count;

    logic [13:0] half_period;
    assign half_period = bit_period >> 1;
    logic [3:0] total_size;
    assign total_size = data_size + 1;

    flex_counter #(.SIZE(14)) clock_counter (
        .clk(clk),
        .n_rst(n_rst),
        .clear(!enable_timer), 
        .count_enable(enable_timer),
        .rollover_val(bit_period),
        .rollover_flag(shift_strobe),
        .count_out(clock_count)
    );

    flex_counter #(.SIZE(4)) bit_counter (
        .clk(clk),
        .n_rst(n_rst),
        .clear(!enable_timer),
        .count_enable(clock_count == half_period),
        .rollover_val(total_size), 
        .rollover_flag(bit_count_done),
        .count_out(bit_count)
    );

    assign packet_done = bit_count_done && shift_strobe;

endmodule

