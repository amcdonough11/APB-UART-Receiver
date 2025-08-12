`timescale 1ns/10ps 

module start_bit_det(
    input logic clk,
    input logic n_rst,
    input logic serial_in,
    output logic new_packet_detected
);

logic rx_meta, rx_sync, rx_sync_d;

always_ff @( posedge clk, negedge n_rst ) begin
    if(~n_rst) begin
        rx_meta <= 1;
        rx_sync <= 1;

        new_packet_detected <= 0;
        rx_sync_d <= 1;
    end
    else begin
        rx_meta <= serial_in;
        rx_sync <= rx_meta;

        new_packet_detected <= (rx_sync_d & ~rx_sync);
        rx_sync_d <= rx_sync;
    end
end

endmodule