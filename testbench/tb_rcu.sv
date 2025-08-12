`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_rcu ();

    localparam CLK_PERIOD = 10ns;

    logic clk, n_rst;
    logic new_packet_detected, framing_error, sbc_clear, sbc_enable, load_buffer, load_enable, packet_done;

    // clockgen
    always begin
        clk = 0;
        #(CLK_PERIOD / 2.0);
        clk = 1;
        #(CLK_PERIOD / 2.0);
    end

    rcu r0 (
        .clk(clk),
        .n_rst(n_rst),
        .new_packet_detected(new_packet_detected),
        .packet_done(packet_done),
        .framing_error(framing_error),
        .sbc_clear(sbc_clear),
        .sbc_enable(sbc_enable),
        .load_buffer(load_buffer),
        .enable_timer(enable_timer)
    );
    task set_tv;
        input logic tv_n_rst;
        input logic tv_new_packet_detected;
        input logic tv_packet_done;
        input logic tv_framing_error;
    begin
        automatic logic tv_sbc_clear;
        automatic logic tv_sbc_enable;
        automatic logic tv_load_buffer;
        automatic logic tv_enable_timer;

        n_rst = tv_n_rst;
        new_packet_detected = tv_new_packet_detected;
        packet_done = tv_packet_done;
        framing_error = tv_framing_error;

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

        //n_rst, new_packet, packet_done, framing_error
        set_tv(0, 0, 0, 0);
        @(negedge clk);
        set_tv(1, 0, 0, 0);
        @(negedge clk);
        set_tv(1, 1, 0, 0); //start_no_error
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        set_tv(1, 0, 1, 0);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);

        set_tv(1, 1, 0, 1); //n_rst
        @(negedge clk);
        set_tv(1, 1, 0, 1); //start_error
        @(negedge clk);
        @(negedge clk);
        set_tv(1, 0, 1, 1);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);


        set_tv(1, 1, 0, 0); // again _no_error
        @(negedge clk);
        @(negedge clk);
        set_tv(1, 0, 1, 0);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);

        $finish;
    end
endmodule

/* verilator coverage_on */

