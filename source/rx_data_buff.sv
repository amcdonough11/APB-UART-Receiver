`timescale 1ns/10ps

module rx_data_buff(
    input logic clk,
    input logic n_rst,
    input logic load_buffer,
    input logic [7:0] packet_data,
    input logic data_read,
    output logic [7:0] rx_data,
    output logic data_ready,
    output logic overrun_error
);
typedef enum logic [1:0] { IDLE, LOAD, READY, ERROR } state_t;
state_t state, next_state;

logic [7:0] next_rx_data;

// State & data registers
always_ff @(posedge clk, negedge n_rst) begin
    if(~n_rst) begin
        state <= IDLE;
        rx_data <= '0;
    end
    else begin
        state <= next_state;
        rx_data <= next_rx_data;
    end
end

always_comb begin
    next_state = state;
    next_rx_data = rx_data;

    data_ready = 0;
    overrun_error = 0;

    case(state)
        IDLE: begin
            next_state = (load_buffer) ? LOAD : IDLE;
        end
        LOAD: begin
            next_rx_data = packet_data;

            next_state = READY;
        end
        READY: begin
            data_ready = 1;

            if(load_buffer) begin
                next_state = ERROR;
            end
            else if(data_read) begin
                next_state = IDLE;
            end
        end
        ERROR: begin
            overrun_error = 1;
            data_ready = 1;
            
            next_state = (data_read) ? IDLE : ERROR;
        end
        default begin
            next_state = (load_buffer) ? LOAD: IDLE;
        end
    endcase
end

endmodule