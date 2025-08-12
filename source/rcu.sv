`timescale 1ns / 10ps

module rcu (
    input logic clk,
    input logic n_rst,
    input logic new_packet_detected,
    input logic packet_done,
    input logic framing_error,
    output logic sbc_clear,
    output logic sbc_enable,
    output logic load_buffer,
    output logic enable_timer
);
    typedef enum logic [2:0] {IDLE, CLEAR_ERROR, STORE_DATA_BITS, LOAD_STOP_BITS, CHECK_STOP_BITS, CHECK_PREVOUS_DATA} state_t;

    state_t state, next_state;


always_ff @ (posedge clk, negedge n_rst) begin
    if(~n_rst) begin
        state <= IDLE;
    end
    else begin
        state <= next_state;
    end
end

always_comb begin
    next_state = state;
    case(state)
        IDLE: next_state = new_packet_detected ? CLEAR_ERROR : IDLE;
        CLEAR_ERROR: next_state = STORE_DATA_BITS;
        STORE_DATA_BITS: next_state = packet_done ? LOAD_STOP_BITS : STORE_DATA_BITS;
        LOAD_STOP_BITS: next_state = CHECK_STOP_BITS;
        CHECK_STOP_BITS:  next_state = framing_error ? IDLE : CHECK_PREVOUS_DATA;
        CHECK_PREVOUS_DATA: next_state = IDLE;
        default: next_state = IDLE;
    endcase
end

always_comb begin
    sbc_clear = 0;
    sbc_enable = 0;
    load_buffer = 0;
    enable_timer = 0;
    case(state)
        IDLE: begin
            sbc_clear = 0;
            sbc_enable = 0;
            load_buffer = 0;
            enable_timer = 0;
        end
        CLEAR_ERROR: begin
            sbc_clear = 1;
            sbc_enable = 0;
            load_buffer = 0;
            enable_timer = 0;
        end
        STORE_DATA_BITS: begin
            sbc_clear = 0;
            sbc_enable = 0;
            load_buffer = 0;
            enable_timer = 1;
        end
        LOAD_STOP_BITS: begin
            sbc_clear = 0;
            sbc_enable = 1;
            load_buffer = 0;
            enable_timer = 0;
        end
        CHECK_STOP_BITS: begin
            sbc_clear = 0;
            sbc_enable = 0;
            load_buffer = 0;
            enable_timer = 0;
        end
        CHECK_PREVOUS_DATA: begin
            sbc_clear = 0;
            sbc_enable = 0;
            load_buffer = 1;
            enable_timer = 0;
        end
        default: begin
            sbc_clear = 0;
            sbc_enable = 0;
            load_buffer = 0;
            enable_timer = 0;
        end
    endcase
end


endmodule

