`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_timer ();

    localparam CLK_PERIOD = 10ns;

    logic clk, n_rst;
    logic enable_timer, shift_strobe, packet_done;

    // clockgen
    always begin
        clk = 0;
        #(CLK_PERIOD / 2.0);
        clk = 1;
        #(CLK_PERIOD / 2.0);
    end

    timer t0 (.clk(clk), .n_rst(n_rst), .enable_timer(enable_timer), .shift_strobe(shift_strobe), .packet_done(packet_done));

    task set_tv;
        input logic tv_n_rst;
        input logic tv_enable_timer;
    begin
        automatic logic tv_shift_strobe;
        automatic logic tv_packet_done;

        n_rst = tv_n_rst;
        enable_timer = tv_enable_timer;
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
        enable_timer = 0;

        reset_dut();
        @(negedge clk);

        //n_rst, enable_timer
        set_tv(0, 0);
        @(negedge clk);
        set_tv(1, 0);
        @(negedge clk);
        set_tv(1, 1);
        @(negedge clk);
        set_tv(1, 1);
        @(negedge clk);
        set_tv(1, 1);
        @(negedge clk);
        set_tv(1, 0);
        @(negedge clk);
        set_tv(1, 1);
        @(negedge clk);
        set_tv(1, 1);
        @(negedge clk);
        set_tv(1, 1);
        @(negedge clk);
        set_tv(1, 1);
        @(negedge clk);
        set_tv(1, 1);
        @(negedge clk);
        set_tv(1, 1);
        @(negedge clk);
        set_tv(1, 1);
        @(negedge clk);

        repeat (9) begin 
            @(negedge clk);
            set_tv(1, 1);
            @(negedge clk);
            set_tv(1, 1);
            @(negedge clk);
            set_tv(1, 1);
            @(negedge clk);
            @(negedge clk);
            set_tv(1, 1);
            @(negedge clk);
            set_tv(1, 1);
            @(negedge clk);
            set_tv(1, 1);
            @(negedge clk);
            set_tv(1, 1);
            @(negedge clk);
            set_tv(1, 1);
            @(negedge clk);
            set_tv(1, 1);
            @(negedge clk);
            set_tv(1, 1);
            @(negedge clk);
        end

        set_tv(1, 1);
        @(negedge clk);
    


        $finish;
    end
endmodule

/* verilator coverage_on */

