`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_apb_subordinate ();

    localparam CLK_PERIOD = 20ns;

    logic clk, n_rst;

    // clockgen
    always begin
        clk = 0;
        #(CLK_PERIOD / 2.0);
        clk = 1;
        #(CLK_PERIOD / 2.0);
    end

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

    logic [7:0] rx_data;
    logic data_ready, overrun_error, framing_error, data_read;

    logic psel;
    logic [2:0] paddr;
    logic penable;
    logic pwrite;
    logic [7:0] pwdata;
    logic [7:0] prdata;
    logic psaterr;
    logic [3:0] data_size;
    logic [13:0] bit_period;

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
        // APB-Subordinate Side
        .psel(psel),
        .paddr(paddr),
        .penable(penable),
        .pwrite(pwrite),
        .pwdata(pwdata),
        .prdata(prdata), //out
        .psaterr(psaterr) 
    );

    apb_subordinate DUT ( .clk(clk),
        .n_rst(n_rst),
        .rx_data(rx_data),
        .data_ready(data_ready),
        .overrun_error(overrun_error),
        .framing_error(framing_error),
        .data_read(data_read),
        .psel(psel),
        .paddr(paddr),
        .penable(penable),
        .pwrite(pwrite),
        .pwdata(pwdata),
        .prdata(prdata), //out
        .psaterr(psaterr),
        .data_size(data_size),
        .bit_period(bit_period)
        );

    task read_buffer;
    begin
        rx_data = 8'd8;
        data_ready = 1;
        overrun_error = 0;
        framing_error = 0;
        
        //for_DUT, write_mode, address, data, expected_error
        enqueue_transaction(1'b1, 1'b0, 3'd6, 8'd0, 1'b0);
        execute_transactions(1);
        @(negedge clk);
    end
    endtask

    task write_then_read_data_size;
    begin
        rx_data = 8'd8;
        data_ready = 1;
        overrun_error = 0;
        framing_error = 0;
        
        //for_DUT, write_mode, address, data, expected_error
        enqueue_transaction(1'b1, 1'b1, 3'd4, 8'd6, 1'b0);
        execute_transactions(1);
        @(negedge clk);

        //for_DUT, write_mode, address, data, expected_error
        enqueue_transaction(1'b1, 1'b0, 3'd4, 8'd6, 1'b0);
        execute_transactions(1);
        @(negedge clk);
    end
    endtask

    task write_then_read_bit_period;
    begin
        rx_data = 8'd8;
        data_ready = 1;
        overrun_error = 0;
        framing_error = 0;
        
        //for_DUT, write_mode, address, data, expected_error
        enqueue_transaction(1'b1, 1'b1, 3'd2, 8'd10, 1'b0);
        execute_transactions(1);
        //for_DUT, write_mode, address, data, expected_error
        enqueue_transaction(1'b1, 1'b1, 3'd3, 8'd05, 1'b0);
        execute_transactions(1);
        @(negedge clk);

        //for_DUT, write_mode, address, data, expected_error
        enqueue_transaction(1'b1, 1'b0, 3'd2, 8'd6, 1'b0);
        execute_transactions(1);
        //for_DUT, write_mode, address, data, expected_error
        enqueue_transaction(1'b1, 1'b0, 3'd3, 8'd6, 1'b0);
        execute_transactions(1);
        @(negedge clk);
    end
    endtask

    
    task read_error;
    begin
        rx_data = 8'd8;
        data_ready = 1;
        overrun_error = 1;
        framing_error = 1;
    
        //for_DUT, write_mode, address, data, expected_error
        enqueue_transaction(1'b1, 1'b0, 3'd1, 8'd6, 1'b0);
        execute_transactions(1);
        @(negedge clk);
    end
    endtask

    task read_status;
    begin
        rx_data = 8'd8;
        data_ready = 1;
        overrun_error = 1;
        framing_error = 1;
    
        //for_DUT, write_mode, address, data, expected_error
        enqueue_transaction(1'b1, 1'b0, 3'd0, 8'd6, 1'b0);
        execute_transactions(1);
        @(negedge clk);
    end
    endtask

    task write_to_readonly;
    begin
        rx_data = 8'd8;
        data_ready = 1;
        overrun_error = 0;
        framing_error = 0;
        
        //for_DUT, write_mode, address, data, expected_error
        enqueue_transaction(1'b1, 1'b1, 3'd1, 8'd6, 1'b0);
        execute_transactions(1);
        @(negedge clk);

        //for_DUT, write_mode, address, data, expected_error
        enqueue_transaction(1'b1, 1'b0, 3'd1, 8'd6, 1'b0);
        execute_transactions(1);
        @(negedge clk);
    end
    endtask
    string test_name;

    initial begin
        test_name = "reset";
        n_rst = 1;
        enqueue_transaction_en = 1'b0;
        transaction_fake  = 1'b0;
        transaction_write = 1'b0;
        transaction_addr  = 3'b0;
        transaction_data  = 8'b0;
        transaction_error = 1'b0;

        reset_model;
        reset_dut;
        @(negedge clk);

        test_name = "read buffer";
        read_buffer;
        test_name = "write_then_read_data_size";
        write_then_read_data_size;
        test_name = "write_then_read_bit_period";
        write_then_read_bit_period;
        test_name = "read_error";
        read_error;
        test_name = "read_status";
        read_status;
        test_name = "write_to_readonly";
        write_to_readonly;
        test_name = "for_dut = 0";
        enqueue_transaction(1'b0, 1'b0, 3'd1, 8'd6, 1'b0);
        execute_transactions(1);


        $finish;
        end
endmodule

/* verilator coverage_on */

