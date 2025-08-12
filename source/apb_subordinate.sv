`timescale 1ns / 10ps

module apb_subordinate #(

) (
    input logic clk,
    input logic n_rst,
    input logic [7:0] rx_data,
    input logic data_ready,
    input logic overrun_error,
    input logic framing_error,
    input logic psel,
    input logic [2:0] paddr,
    input logic penable,
    input logic pwrite,
    input logic [7:0] pwdata,
    output logic data_read,
    output logic [7:0] prdata,
    output logic psaterr,
    output logic [3:0] data_size,
    output logic [13:0] bit_period
);

typedef enum logic [1:0] {IDLE,ADDRESS, DATA} state_t;
state_t state;

logic [7:0]  data_status_reg;
logic [7:0]  error_status_reg;
logic [13:0] bit_period_reg;
logic [7:0]  data_size_reg;
logic [7:0]  data_buffer_reg;

logic [7:0] next_bit_period_reg_low;
logic [5:0] next_bit_period_reg_high;
logic [7:0] next_data_size_reg;
logic [7:0] next_prdata;
logic next_psaterr;

always_ff @ (posedge clk, negedge n_rst) begin
    if(~n_rst) begin
        prdata <= 0;
    end
    else begin
        prdata <= next_prdata;
    end
end

//interface states
/*always_comb begin 
    next_state = state;
    data_read = 0;
    case(state)
        IDLE: begin 
            if(psel && penable) next_state = DATA;
        end
        DATA: begin 
            data_read = !pwrite;
            if (!psel) begin
                    next_state = IDLE;
            end
        end
        default: next_state = IDLE;
    endcase
end*/

always_comb begin 
    data_read = 0;
    case(psel)
        0: state = IDLE;
        1: begin
            case(penable)
                0: state = ADDRESS;
                1: begin 
                    data_read = (paddr == 3'h6) && !pwrite;
                    state = DATA;
                end
                default: state = DATA;
            endcase
        end
        default: state = IDLE;
    endcase
end


//read
always_comb begin
    next_prdata = prdata;
    if(state == ADDRESS && ~pwrite) begin
        case(paddr) 
            0: next_prdata = data_status_reg; 
            1: next_prdata = error_status_reg;
            2: next_prdata = bit_period_reg[7:0];
            3: next_prdata = {2'b0, bit_period_reg[13:8]};
            4: next_prdata = data_size_reg;
            6: next_prdata = data_buffer_reg;
            default: next_prdata = 0;
        endcase
    end
end

//write regs
always_ff @ (posedge clk, negedge n_rst) begin
    if(~n_rst) begin
        bit_period_reg <= 10;
        data_size_reg <= 8;
        psaterr <= 0;
    end
    else begin
            bit_period_reg[7:0] <= next_bit_period_reg_low;
            bit_period_reg[13:8] <= next_bit_period_reg_high;
            data_size_reg <= next_data_size_reg;
            psaterr <= next_psaterr;
    end
end

always_comb begin
    next_psaterr = 0;
    next_bit_period_reg_low = bit_period_reg[7:0];
    next_bit_period_reg_high = bit_period_reg[13:8];
    next_data_size_reg = data_size_reg;
    if (state == ADDRESS && pwrite) begin
        case(paddr)
            2: next_bit_period_reg_low = pwdata;
            3: next_bit_period_reg_high = pwdata[5:0];
            4: next_data_size_reg = pwdata;
            default: next_psaterr = 1;
        endcase
    end
end

//set reg
always_ff @ (posedge clk, negedge n_rst) begin
    if(~n_rst) begin
        data_status_reg <= 0;
        error_status_reg <= 0;
        data_buffer_reg <= 0;
    end
    else begin
        data_status_reg <= {7'b0, data_ready};
        error_status_reg <= {6'b0, overrun_error, framing_error};
        data_buffer_reg <= rx_data;
    end
end

assign data_size  = data_size_reg[3:0];
assign bit_period = bit_period_reg;
endmodule

