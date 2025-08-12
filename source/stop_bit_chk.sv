`timescale 1ns/10ps

module stop_bit_chk(
    input logic clk,
    input logic n_rst,
    input logic stop_bit,
    input logic sbc_enable,
    input logic sbc_clear,
    output logic framing_error
);
logic next_framing_error;

always_comb begin
    next_framing_error = framing_error;
    if(sbc_enable) begin
        next_framing_error = ~stop_bit;
    end

    if(sbc_clear) begin
        next_framing_error = 0;
    end
end

always_ff @(posedge clk, negedge n_rst) begin
    if(~n_rst) begin
        framing_error <= 0;
    end
    else begin
        framing_error <= next_framing_error;
    end
end

endmodule