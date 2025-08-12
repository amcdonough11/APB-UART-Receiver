`timescale 1ns / 10ps

module sr_9bit (
    input logic clk,
    input logic n_rst,
    input logic shift_strobe,
    input logic serial_in,
    input logic [3:0] data_size,
    output logic [7:0] packet_data,
    output logic stop_bit
);
logic serial_out;
logic [8:0] parallel_out;
flex_sr #(.SIZE(9)) f0 (.clk(clk),
    .n_rst(n_rst),
    .shift_enable(shift_strobe),
    .load_enable(1'b0),
    .serial_in(serial_in),
    .parallel_in(9'b0),
    .serial_out(serial_out),
    .parallel_out(parallel_out)
);

always_comb begin
        case (data_size)
            4'd5: begin
                packet_data = {3'b0, parallel_out[7:3]};
                stop_bit = parallel_out[8];
            end
            4'd7: begin
                packet_data = {1'b0, parallel_out[7:1]};
                stop_bit = parallel_out[8];
            end
            4'd8: begin
                packet_data = parallel_out[7:0];
                stop_bit = parallel_out[8];
            end
            default: begin
                packet_data = parallel_out[7:0];
                stop_bit = parallel_out[8];
            end
        endcase
    end

endmodule

