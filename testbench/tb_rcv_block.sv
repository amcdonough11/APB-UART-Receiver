`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_rcv_block ();

    localparam CLK_PERIOD = 2.5ns; //10

    logic clk, n_rst;
    logic serial_in;
    logic data_read;
    logic [7:0] rx_data;
    logic overrun_error;
    logic framing_error;
    logic data_ready;
    logic [3:0] data_size;
    logic [13:0] bit_period;

    // clockgen
    always begin
        clk = 0;
        #(CLK_PERIOD / 2.0);
        clk = 1;
        #(CLK_PERIOD / 2.0);
    end

    rcv_block dut (
        .clk(clk),
        .n_rst(n_rst),
        .serial_in(serial_in),
        .data_read(data_read),
        .data_size(data_size),
        .bit_period(bit_period),
        .rx_data(rx_data),
        .data_ready(data_ready),
        .overrun_error(overrun_error),
        .framing_error(framing_error)
    );

    task reset_dut;
    begin
        n_rst = 0;
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        n_rst = 1;
        @(negedge clk);
        @(negedge clk);
    end
    endtask

    task send_packet;
        input [7:0] data;
        input stop_bit;
        input time data_period;
        
        integer i;
        begin
            // First synchronize to away from clock's rising edge
            @(negedge clk)
            
            // Send start bit
            serial_in = 1'b0;
            #data_period;
            
            // Send data bits
            for (i = 0; i < 8; i = i + 1)
            begin
                serial_in = data[i];
                #data_period;
            end
            
            // Send stop bit
            serial_in = stop_bit;
            #data_period;
        end
    endtask

        task fe_packet;
        input [7:0] data;
        input stop_bit;
        input time data_period;
        
        integer i;
        begin
            // First synchronize to away from clock's rising edge
            @(negedge clk)
            
            // Send start bit
            serial_in = 1'b0;
            #data_period;
            
            // Send data bits
            for (i = 0; i < 8; i = i + 1)
            begin
                serial_in = data[i];
                #data_period;
            end
            
            // Send stop bit
            serial_in = 1'b0;
            #data_period;
        end
    endtask



    initial begin
        n_rst = 1;
        data_read = 1;
        serial_in = 1'b1;
        data_size = 8;
        bit_period = 10;

        reset_dut();

        //data, stop_bit, data_period
        send_packet(8'b10000001, 1'b1, 25ns); //send data
        #75ns;
        send_packet(8'b10101001, 1'b1, 26ns); //send data slow
        #75ns;
        send_packet(8'b10000001, 1'b1, 24ns); //send data fast
        data_read = 0;
        #75ns;
        send_packet(8'b01010111, 1'b1, 25ns); //overrun error
        #75ns;
        data_read = 1;
        fe_packet(8'b01111110, 1'b1, 25ns); //framing error
        #75ns;



        $finish;
    end
endmodule

/* verilator coverage_on */

