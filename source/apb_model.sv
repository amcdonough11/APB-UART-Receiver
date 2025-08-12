`timescale 1ns/10ps

module apb_model #(
  parameter int ADDR_W = 3,
  parameter int DATA_W = 8
)(
  input  logic                 clk,

  // Testbench controls
  input  logic                 model_reset,
  input  logic                 enable_transactions,

  // Transaction enqueue (TB pulses this very briefly)
  input  logic                 enqueue_transaction,
  input  logic                 transaction_write,
  input  logic                 transaction_fake,
  input  logic [ADDR_W-1:0]    transaction_addr,
  input  logic [DATA_W-1:0]    transaction_data,
  input  logic                 transaction_error,

  // Progress reporting
  output integer               current_transaction_num,

  // APB-Subordinate side
  output logic                 psel,
  output logic [ADDR_W-1:0]    paddr,
  output logic                 penable,
  output logic                 pwrite,
  output logic [DATA_W-1:0]    pwdata,
  input  logic [DATA_W-1:0]    prdata,
  input  logic                 psaterr
);

  // --------- Transaction queue ----------
  typedef struct packed {
    logic                 do_write;
    logic                 is_fake;
    logic [ADDR_W-1:0]    addr;
    logic [DATA_W-1:0]    data;
    logic                 expect_err;
  } txn_t;

  txn_t q[$];
  txn_t cur;
  logic have_cur;

  integer tx_count;
  assign current_transaction_num = tx_count;

  // Because TB pulses enqueue for ~0.1 ns, capture on its posedge (TB-only, fine for a BFM)
  always @(posedge enqueue_transaction or posedge model_reset) begin
    if (model_reset) begin
      q.delete();
    end else begin
      txn_t t;
      t.do_write   = transaction_write;
      t.is_fake    = transaction_fake;
      t.addr       = transaction_addr;
      t.data       = transaction_data;
      t.expect_err = transaction_error;
      q.push_back(t);
      // $display("[%0t] BFM: enqueued %s @0x%0h data=0x%0h exp_err=%0b",
      //          $time, t.do_write ? "WRITE" : "READ", t.addr, t.data, t.expect_err);
    end
  end

  // --------- Simple APB master FSM (no PREADY; fixed 2-cycle transfer) ----------
  typedef enum logic [1:0] {IDLE, SETUP, ACCESS} state_t;
  state_t state;

  always_ff @(posedge clk or posedge model_reset) begin
    if (model_reset) begin
      state    <= IDLE;
      psel     <= 1'b0;
      penable  <= 1'b0;
      pwrite   <= 1'b0;
      paddr    <= '0;
      pwdata   <= '0;
      have_cur <= 1'b0;
      tx_count <= 0;
    end else begin
      unique case (state)
        IDLE: begin
          // Bus idle
          psel    <= 1'b0;
          penable <= 1'b0;

          // Load next txn when enabled
          if (enable_transactions) begin
            if (!have_cur && q.size() != 0) begin
              cur      <= q.pop_front();
              have_cur <= 1'b1;
            end

            if (have_cur) begin
              if (cur.is_fake) begin
                // Skip driving bus, just count it
                tx_count <= tx_count + 1;
                have_cur <= 1'b0;
              end else begin
                // SETUP phase
                psel    <= 1'b1;
                penable <= 1'b0;
                pwrite  <= cur.do_write;
                paddr   <= cur.addr;
                pwdata  <= cur.data;
                state   <= SETUP;
              end
            end
          end
        end

        SETUP: begin
          // ACCESS phase
          penable <= 1'b1;      // psel remains 1
          state   <= ACCESS;
        end

        ACCESS: begin
          // Complete transfer in this cycle
          if (psaterr !== cur.expect_err) begin
            $error("[%0t] BFM: psaterr mismatch @0x%0h. expected=%0b got=%0b",
                   $time, cur.addr, cur.expect_err, psaterr);
          end
          // Optional read trace:
          // if (!cur.do_write) $display("[%0t] BFM: READ  @0x%0h -> 0x%0h", $time, cur.addr, prdata);

          // Deassert bus and advance
          psel     <= 1'b0;
          penable  <= 1'b0;
          tx_count <= tx_count + 1;
          have_cur <= 1'b0;
          state    <= IDLE;
        end
      endcase
    end
  end
endmodule
