`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_sr_9bit ();

    localparam CLK_PERIOD = 10ns;

    logic clk, n_rst;
    logic shift_strobe, serial_in, stop_bit;
    logic [7:0] packet_data;

    // clockgen
    always begin
        clk = 0;
        #(CLK_PERIOD / 2.0);
        clk = 1;
        #(CLK_PERIOD / 2.0);
    end

    sr_9bit s0 (.clk(clk), .n_rst(n_rst), .shift_strobe(shift_strobe), .serial_in(serial_in), .packet_data(packet_data), .stop_bit(stop_bit));

    task set_tv;
        input logic tv_n_rst;
        input logic tv_shift_strobe;
        input logic tv_serial_in;
    begin
        automatic logic tv_stop_bit;
        automatic logic [7:0] tv_packet_data;

        n_rst = tv_n_rst;
        shift_strobe = tv_shift_strobe;
        serial_in = tv_serial_in;
    
    end
    endtask

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

    initial begin
        n_rst = 1;

        reset_dut();
        
        //n_rst, shift_strobe, serial_in
        set_tv(0, 0, 0);
        @(negedge clk);
        set_tv(1, 1, 0); //1
        @(negedge clk);
        set_tv(1, 1, 0); //2
        @(negedge clk);
        set_tv(1, 1, 0); //3
        @(negedge clk);
        set_tv(1, 1, 0); //4
        @(negedge clk);
        set_tv(1, 1, 0); //5
        @(negedge clk);
        set_tv(1, 1, 0); //6
        @(negedge clk);
        set_tv(1, 1, 0); //7
        @(negedge clk);
        set_tv(1, 1, 0); //8
        @(negedge clk);
        set_tv(1, 1, 1); //9
        @(negedge clk);



        $finish;
    end
endmodule

/* verilator coverage_on */

