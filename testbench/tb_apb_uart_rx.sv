`timescale 1ns / 10ps
/* verilator coverage_off */
// verilator lint_off REALCVT
/* verilator lint_off WIDTHEXPAND */

module tb_apb_uart_rx ();

    localparam CLK_PERIOD = 20ns;

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
        $dumpvars(0, tb_apb_uart);
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

    task send_packet;
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

    task read;
        input [2:0] add;
        begin
            enqueue_transaction(1,0,add,0,0);
            execute_transactions(1);
        end
    endtask

    task write;
        input [2:0] add;
        input [7:0] data;
        begin
            enqueue_transaction(1,0,add,data,0);
            execute_transactions(1);
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

    task configure_design;
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

    task streaming;
        input [7:0] data;
        begin
            send_packet(data, 1'b1, 200ns);
        end
    endtask

    task power_on_reset;
    begin
        reset_model();
        reset_dut();
        serial_in = 1'b1;
        #100ns;
    end
    endtask

    task check_output;
        input [2:0] address;
        input [7:0] expected_data;
        input string check_name;
        begin
            $display("%t: Checking %s at address %0h", $time, check_name, address);
            read(address);
            #1ns;
            
            if(prdata === expected_data) begin
                $display("PASS - %s: Expected %b, Got %b", 
                    check_name, expected_data, prdata);
            end else begin
                $display("FAIL - %s: Expected %b, Got %b", 
                    check_name, expected_data, prdata);
            end
        end
    endtask

    task stream_data;
        input [7:0] data [];
        input time data_period;
        integer i;
        begin
            @(negedge clk);
            
            for(i = 0; i < data.size(); i++) begin
                send_packet(data[i], 1'b1, data_period);

                enqueue_transaction(0,1,4,'0,0);
                execute_transactions(12);

                check_output(0, 1, "stream data data status");

                enqueue_transaction(0,1,4,'0,0);
                execute_transactions(4);

                check_output(6, data[i], "stream data data reg");
            end
        end
    endtask

    task five_send_packet;
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

    task five_stream_data;
        input [4:0] data [];
        input time data_period;
        integer i;
        begin
            @(negedge clk);
            
            for(i = 0; i < data.size(); i++) begin
                five_send_packet(data[i], 1'b1, data_period);
                
                enqueue_transaction(0,1,4,'0,0);
                execute_transactions(12);

                check_output(0, 1, "5 bit stream data status");

                enqueue_transaction(0,1,4,'0,0);
                execute_transactions(4);

                check_output(6, data[i], "5 bit stream data reg");
            end
        end
    endtask

    task run_test_sequence;
        input [13:0] bit_period;
        input [3:0] data_size;
        input [7:0] test_data [];
        begin
            configure_design(bit_period, data_size);
            
            stream_data(test_data, 200ns);
        end
    endtask

    task five_run_test_sequence;
        input [13:0] bit_period;
        input [3:0] data_size;
        input [4:0] test_data [];
        begin
            power_on_reset();
            configure_design(bit_period, data_size);
            #100ns;
            
            five_stream_data(test_data, 200ns);
            
        end
    endtask

    task seven_send_packet;
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

    task seven_stream_data;
        input [6:0] data [];
        input time data_period;
        integer i;
        begin
            @(negedge clk);
            
            for(i = 0; i < data.size(); i++) begin
                seven_send_packet(data[i], 1'b1, data_period);

                enqueue_transaction(0,1,4,'0,0);
                execute_transactions(12);

                check_output(0, 1, "7 bit stream data status");

                enqueue_transaction(0,1,4,'0,0);
                execute_transactions(4);

                check_output(6, data[i], "7 bit stream data reg");
            end
        end
    endtask

    task seven_run_test_sequence;
        input [13:0] bit_period;
        input [3:0] data_size;
        input [6:0] test_data [];
        begin
            configure_design(bit_period, data_size);
            #100ns;
            
            
            seven_stream_data(test_data, 200ns);
        
        end
    endtask

    task bit_per_20_run_test_sequence;
        input [13:0] bit_period;
        input [3:0] data_size;
        input [7:0] test_data [];
        begin
            configure_design(bit_period, data_size);
            #100ns;
            
            stream_data(test_data, 400ns);
        
        end
    endtask

    task seven_bit_per_20_run_test_sequence;
        input [13:0] bit_period;
        input [3:0] data_size;
        input [6:0] test_data [];
        begin
            configure_design(bit_period, data_size);
            #100ns;
            
            seven_stream_data(test_data, 400ns);
        end
    endtask

    string test_name;

    initial begin

        automatic logic [7:0] test_data1 [] = '{8'b10101010};
        automatic logic [7:0] test_data2 [] = '{8'b11001100, 8'b00110011};
        automatic logic [4:0] small_test_data [] = '{5'b10101};
        automatic logic [6:0] med_test_data [] = '{7'b1010101};
        automatic logic [6:0] med_test_data1 [] = '{7'b1010101, 7'b0111001};

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

        /*Test 1: Config and Send One Byte*/

        test_name = "first config";

        //bit period = 10; data_size = 8
        configure_design(14'd10, 4'd8);

        test_name = "stream 8 bit";
        streaming(8'b10101010);

        enqueue_transaction(0,1,4,'0,0);
        execute_transactions(12);

        test_name = "stream 8 bit data status";
        check_output(0, 1, test_name);

        enqueue_transaction(0,1,4,'0,0);
        execute_transactions(4);

        test_name = "stream 8 bit buffer";
        check_output(6, 8'b10101010, test_name);

        enqueue_transaction(0,1,4,'0,0);
        execute_transactions(10);

        /*Test 2: Run_Test_Sequence*/

        test_name = "Single Byte Test";
        run_test_sequence(14'd10, 4'd8, test_data1);

        enqueue_transaction(0,1,4,'0,0);
        execute_transactions(10);

        /*Test 3: Run_Test_Sequence on Multiple Bytes*/

        test_name = "Multiple Byte Test";
        run_test_sequence(14'd10, 4'd8, test_data2);
        #1000ns;

        /*Test 4: 5 Byte Size*/

        test_name = "5 Byte Size";
        five_run_test_sequence(14'd10, 4'd5, small_test_data);
        #1000ns;

        /*Test 5: 7 Byte Size*/
        test_name = "7 Byte Size";
        seven_run_test_sequence(14'd10, 4'd7, med_test_data);
        #1000ns;

        /*Test 6: Change Bit Peroid, Single Byte*/
        test_name = "Change Bit Per Single Byte Test";
        bit_per_20_run_test_sequence(14'd20, 4'd8, test_data1);
        #1000ns;

        /*Test 7: Change Bit Peroid, Multiple Byte*/
        test_name = "Change Bit Per Multiple Byte Test";
        bit_per_20_run_test_sequence(14'd20, 4'd8, test_data2);
        #1000ns;

        /*Test 8: Change Bit Peroid and Bit SIze, Multiple Byte*/
        test_name = "Change Bit Per and Size Multiple Byte Test";
        seven_bit_per_20_run_test_sequence(14'd20, 4'd7, med_test_data1);
        #1000ns;

        /*Test 9: Overrun Error*/
        test_name = "Overrun Error";
        configure_design(14'd10, 4'd8);

        streaming(8'b10101010);

        enqueue_transaction(0,1,4,'0,0);
        execute_transactions(12);

        streaming(8'b11001100);

        read(6);

        /*Test 10: Framing Error*/
        test_name = "Framing Error";
        configure_design(14'd10, 4'd5);

        streaming(8'b00000000);

        enqueue_transaction(0,1,4,'0,0);
        execute_transactions(12);

        
        
        $finish;
    end
endmodule

/* verilator coverage_on */
// verilator lint_on REALCVT
/* verilator lint_on WIDTHEXPAND */
