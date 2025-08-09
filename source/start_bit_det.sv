`timescale 1ns/10ps 

module start_bit_det(
    input logic clk,
    input logic n_rst,
    input logic serial_in,
    output logic new_packet_detected
);

always_ff @( posedge clk, negedge n_rst ) begin
    if(~n_rst) begin
        new_packet_detected <= 0;
    end
    else begin
        new_packet_detected <= ~serial;
    end
end

endmodule