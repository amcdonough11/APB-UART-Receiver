`timescale 1ns / 10ps
/* verilator coverage_off */
// verilator lint_off REALCVT
/* verilator lint_off WIDTHEXPAND */

module tb_apb_uart_rx ();

    localparam CLK_PERIOD = 2.5ns;

    logic clk, n_rst;

    // clockgen
    always begin
        clk = 0;
        #(CLK_PERIOD / 2.0);
        clk = 1;
        #(CLK_PERIOD / 2.0);
    end

    initial begin
        $dumpfile("sim.vcd");
        $dumpvars(0, tb_apb_uart_rx);
    end

    task reset_dut;
    begin
        serial_in = 1;
        n_rst = 0;
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        n_rst = 1;
        @(negedge clk);
        @(negedge clk);
    end
    endtask

    // bus model signals
    logic enqueue_transaction_en;
    logic transaction_write;
    logic transaction_fake;
    logic [2:0] transaction_addr;
    logic [7:0] transaction_data;
    logic transaction_error;
    
    logic model_reset;
    logic enable_transactions;
    integer current_transaction_num;

    logic psel;
    logic [2:0] paddr;
    logic penable;
    logic pwrite;
    logic [7:0] pwdata;
    logic [7:0] prdata;
    logic psaterr;
    logic serial_in;

    // bus model tasks
    task reset_model;
    begin
        model_reset = 1'b1;
        #(0.1);
        model_reset = 1'b0;
    end
    endtask

    task enqueue_transaction;
        input logic for_dut;
        input logic write_mode;
        input logic [2:0] address;
        input logic [7:0] data;
        input logic expected_error;
    begin
        // Make sure enqueue flag is low (will need a 0->1 pulse later)
        enqueue_transaction_en = 1'b0;
        #0.1ns;

        // Setup info about transaction
        transaction_fake  = ~for_dut;
        transaction_write = write_mode;
        transaction_addr  = address;
        transaction_data  = data;
        transaction_error = expected_error;

        // Pulse the enqueue flag
        enqueue_transaction_en = 1'b1;
        #0.1ns;
        enqueue_transaction_en = 1'b0;
    end
    endtask

    task execute_transactions;
        input integer num_transactions;
        integer wait_var;
    begin
        // Activate the bus model
        enable_transactions = 1'b1;
        @(posedge clk);
    
        // Process the transactions
        for(wait_var = 0; wait_var < num_transactions; wait_var++) begin
            @(posedge clk);
            @(posedge clk);
        end
    
        // Turn off the bus model
        @(negedge clk);
        enable_transactions = 1'b0;
    end
    endtask

    // bus model connections
    apb_model BFM ( .clk(clk),
        // Testing setup signals
        .enqueue_transaction(enqueue_transaction_en),
        .transaction_write(transaction_write),
        .transaction_fake(transaction_fake),
        .transaction_addr(transaction_addr),
        .transaction_data(transaction_data),
        .transaction_error(transaction_error),
        // Testing controls
        .model_reset(model_reset),
        .enable_transactions(enable_transactions),
        .current_transaction_num(current_transaction_num),
        // APB-Satellite Side
        .psel(psel),
        .paddr(paddr),
        .penable(penable),
        .pwrite(pwrite),
        .pwdata(pwdata),
        .prdata(prdata),
        .psaterr(psaterr)
    );

    apb_uart_rx DUT (.clk(clk), .n_rst(n_rst), .serial_in(serial_in), .psel(psel), 
    .paddr(paddr), .penable(penable), .pwrite(pwrite), .pwdata(pwdata), 
    .prdata(prdata), .psaterr(psaterr));

    task automatic configure_design;
        input logic [13:0] bit_per;
        input logic [3:0] data_sz;
        begin
            enqueue_transaction(1,1,4,{4'b0, data_sz},0);
            execute_transactions(1);

            enqueue_transaction(1,1,2,bit_per[7:0],0);
            execute_transactions(1);

            enqueue_transaction(1,1,3,{2'b0, bit_per[13:8]},0);
            execute_transactions(1);

        end
    endtask

    task automatic power_on_reset;
    begin
        reset_model();
        reset_dut();
        serial_in = 1'b1;
        #100ns;
    end
    endtask

        task automatic send_packet;
        input [7:0] data;
        input stop_bit;
        input time data_period;
        
        integer i;
        begin
            @(negedge clk)
            
            serial_in = 1'b0;
            #data_period;
            
            for (i = 0; i < 8; i = i + 1)
            begin
                serial_in = data[i];
                #data_period;
            end
            
            serial_in = stop_bit;
            #data_period;
        end
    endtask

    task automatic five_send_packet;
        input [4:0] data;
        input stop_bit;
        input time data_period;
        
        integer i;
        begin
            @(negedge clk)
            
            serial_in = 1'b0;
            #data_period;
            
            for (i = 0; i < 5; i = i + 1)
            begin
                serial_in = data[i];
                #data_period;
            end
            
            serial_in = stop_bit;
            #data_period;
        end
    endtask

    task automatic seven_send_packet;
        input [6:0] data;
        input stop_bit;
        input time data_period;
        
        integer i;
        begin
            @(negedge clk)
            
            serial_in = 1'b0;
            #data_period;
            
            for (i = 0; i < 7; i = i + 1)
            begin
                serial_in = data[i];
                #data_period;
            end
            
            serial_in = stop_bit;
            #data_period;
        end
    endtask

    task automatic singleByteUART;
    input logic [7:0] data;
    input int unsigned data_size;
    input time bit_period;
    begin
        if(data_size == 5) begin
            five_send_packet(data[4:0], 1'b1, bit_period * CLK_PERIOD); 
        end
        else if (data_size == 7) begin
            seven_send_packet(data[6:0], 1'b1, bit_period * CLK_PERIOD);
        end
        else begin
            send_packet(data, 1'b1, bit_period * CLK_PERIOD);
        end

        #(bit_period * CLK_PERIOD)
        enqueue_transaction(1,0,0,1,0);
        enqueue_transaction(1,0,6,data,0);
        execute_transactions(2);
    end
    endtask

    task automatic streamByteUART;
    input logic [7:0] data;
    input int unsigned data_size;
    input time bit_period;
    begin
        if(data_size == 5) begin
            five_send_packet(data[4:0], 1'b1, bit_period * CLK_PERIOD); 
        end
        else if (data_size == 7) begin
            seven_send_packet(data[6:0], 1'b1, bit_period * CLK_PERIOD);
        end
        else begin
            send_packet(data, 1'b1, bit_period * CLK_PERIOD);
        end
    end
    endtask

    task automatic pollOutput;
        input logic [7:0] data;
    begin
        enqueue_transaction(1,0,0,1,0);
        enqueue_transaction(1,0,6,data,0);
        execute_transactions(2);
    end
    endtask

task automatic multiByteUART(
    input int unsigned data_size,
    input time bit_period
);
    int unsigned limit = 1 << data_size;
    byte unsigned last, next;

    last = '0;
    streamByteUART(last, data_size, bit_period);

    for (int unsigned i = 1; i < limit; i++) begin
        next = byte'( i & ((1 << data_size) - 1) ); //Forces next to be right aligned and zero padded for data_size < 8

        pollOutput(last);
        #(CLK_PERIOD);
        streamByteUART(next, data_size, bit_period);

        last = next;
    end

    pollOutput(last);
endtask

    string test_name;

    initial begin

        test_name = "reset";
        n_rst = 1;
        enqueue_transaction_en = 1'b0;
        enable_transactions = 1'b0;
        transaction_fake  = 1'b0;
        transaction_write = 1'b0;
        transaction_addr  = 3'b0;
        transaction_data  = 8'b0;
        transaction_error = 1'b0;
        serial_in = 1;

        reset_model();
        reset_dut();

        serial_in = 1;

        /* Test 1: 8 bit, 10 clk bit period */
        test_name = "Test 1: 8 bit, 10 clk bit period ";

        configure_design(14'd10, 4'd8);

        singleByteUART(8'b10101010, 8, 10);

        multiByteUART(8, 10);

        /* Test 2: 5 bit, 10 clk bit period */
        test_name = "Test 2: 5 bit, 10 clk bit period";

        configure_design(14'd10, 4'd5);

        singleByteUART(5'b00000, 5, 10);

        multiByteUART(5, 10);

        /* Test 3: 7 bit, 10 clk bit period */
        test_name = "Test 3: 7 bit, 10 clk bit period";

        configure_design(14'd10, 4'd7);

        singleByteUART(7'b0110000, 7, 10);

        multiByteUART(7, 10);

        /* Test 4: 8 bit, 11 clk bit period */ 
        test_name = "Test 1: 8 bit, 10 clk bit period ";

        configure_design(14'd11, 4'd8);

        multiByteUART(8, 11);

        /* Test 5: 8 bit, 9 clk bit period */
        test_name = "Test 1: 8 bit, 10 clk bit period ";

        configure_design(14'd9, 4'd8);

        multiByteUART(8, 9);

        /* Test 6: 5 bit, 11 clk bit period */ 
        test_name = "Test 1: 8 bit, 10 clk bit period ";

        configure_design(14'd11, 4'd5);

        multiByteUART(5, 11);

        /* Test 7: 5 bit, 9 clk bit period */
        test_name = "Test 1: 8 bit, 10 clk bit period ";

        configure_design(14'd9, 4'd5);

        multiByteUART(5, 9);

        /* Test 8: 7 bit, 11 clk bit period */ 
        test_name = "Test 1: 8 bit, 10 clk bit period ";

        configure_design(14'd11, 4'd7);

        multiByteUART(7, 11);

        /* Test 9: 7 bit, 9 clk bit period */
        test_name = "Test 1: 8 bit, 10 clk bit period ";

        configure_design(14'd9, 4'd7);

        multiByteUART(7, 9);

        /* Test 10: Overrun Error */
        configure_design(14'd9, 4'd7);

        test_name = "Overrun Error";
        configure_design(14'd10, 4'd8);

        send_packet(8'b10101010, 1'b1, 10 * CLK_PERIOD);

        #(10 * CLK_PERIOD);

        enqueue_transaction(1,0,1,1,0);
        execute_transactions(1);

        send_packet(8'b11101010, 1'b1, 10 * CLK_PERIOD);
        #(10 * CLK_PERIOD);

        enqueue_transaction(1,0,6,8'b10101010,1);
        execute_transactions(1);

        /* Test 11: Framing Error */
        test_name = "Framing Error";
        configure_design(14'd10, 4'd5);

        send_packet(8'b00000000, 1'b1, 10 * CLK_PERIOD);

        #(10 * CLK_PERIOD);

        enqueue_transaction(1,0,1,2,1);
        execute_transactions(1);

        $finish;
    end
endmodule

/* verilator coverage_on */
// verilator lint_on REALCVT
/* verilator lint_on WIDTHEXPAND */
