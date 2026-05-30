`default_nettype none
`timescale 1ns/1ps

// Convolution module, useful for FIR filter.

//  Assumes it is reading single cycle memory, can implement ready/valid
//  handshake if multicycle memory is needed.

module convolution (
   /*AUTOARG*/
   // Outputs
   conv_out, conv_valid, sample_sel,
   // Inputs
   clk, conv_ready, rst, sample_a, sample_b
   );

   parameter NSAMPLES = 64; // Samples to convolve
   parameter NINPUT = 16; // Input bus width
   localparam NOUTPUT = $clog2(NSAMPLES) + 2*NINPUT; // Output bus width
   localparam NSAMPLE_BUS = $clog2(NSAMPLES);

   input wire [NINPUT-1:0] sample_a, sample_b;
   input wire              clk, rst, conv_ready;

   output logic [NSAMPLE_BUS-1:0] sample_sel;
   output logic [NOUTPUT-1:0]     conv_out;
   output logic                   conv_valid;

   typedef enum logic [1:0] {IDLE, RESET_MULT, CONVOLVE, ERROR} conv_state_t;

   conv_state_t state, next_state;
   logic [$clog2(NSAMPLES-1)-1:0] valid_counter, next_valid_counter;
   logic [NSAMPLE_BUS-1:0]        next_sample_sel;

   always_ff @(posedge clk) begin : conv_state
      if (rst) begin
         state <= IDLE;
         /*AUTORESET*/
      end else begin
         state         <= next_state;
         sample_sel    <= next_sample_sel;
         valid_counter <= next_valid_counter;
      end
   end : conv_state

   logic mult_ready, mult_valid, mult_rst, mult_ena, accum_ena, accum_rst;

   always_comb begin : conv_state_comb
      if (rst) begin
              next_state         = IDLE;
              accum_ena          = 0;
              accum_rst          = 1;
              mult_ena           = 0;
              mult_rst           = 1;
              mult_ready         = 0;
              conv_valid         = 0;
              next_sample_sel    = 0;
              next_valid_counter = 0;
      end else begin
         case (state)
           IDLE: begin
              if (conv_ready) begin
                next_state = RESET_MULT;
              end else begin
                next_state = IDLE;
              end
              accum_ena          = 0;
              accum_rst          = 0;
              mult_ena           = 0;
              mult_rst           = 1;
              mult_ready         = 0;
              conv_valid         = 1;
              next_sample_sel    = 0;
              next_valid_counter = 0;
           end // case: IDLE
           RESET_MULT: begin
              next_state         = CONVOLVE;
              accum_ena          = 0;
              accum_rst          = 1;
              mult_ena           = 0;
              mult_rst           = 1;
              mult_ready         = 1;
              conv_valid         = 0;
              next_sample_sel    = NSAMPLES - 1;
              next_valid_counter = NSAMPLES - 1;
           end // case: RESET_MULT
           CONVOLVE: begin
              if ((valid_counter == 0) & mult_valid) begin
                 next_state = IDLE;
              end else begin
                 next_state = CONVOLVE;
              end
              accum_ena          = mult_valid;
              accum_rst          = 0;
              mult_ena           = 1;
              mult_rst           = 0;
              mult_ready         = 1;
              conv_valid         = 0;
              next_sample_sel    = (sample_sel == 0) ? 0 : sample_sel - 1;
              next_valid_counter = (mult_valid) ? valid_counter - 1 : valid_counter;
           end // case: CONVOLVE
           ERROR: begin
              // Halt and catch fire
              next_state         = ERROR;
              accum_ena          = 0;
              accum_rst          = 0;
              mult_ena           = 0;
              mult_rst           = 0;
              mult_ready         = 0;
              conv_valid         = 0;
              next_sample_sel    = 0;
              next_valid_counter = 0;
           end // case: ERROR
         endcase // case (state)
      end
   end : conv_state_comb

   wire [2*NINPUT-1:0] product;
   booth_pipelined_multiplier #(.N(NINPUT)) multiplier
     (.valid  (mult_valid),
      .ready  (mult_ready),
      .rst    (mult_rst),
      .a      (sample_a),
      .b      (sample_b),
      .ena    (mult_ena),
      .product(product),
      .clk    (clk),
      .frame  ());

   logic [NOUTPUT-1:0] product_ext, sum, accum;
   assign conv_out    = accum;
   assign product_ext = {{NSAMPLE_BUS {product[2*NINPUT-1]}}, product};
   always_comb sum = product_ext + accum;

   always_ff @(posedge clk) begin : accumulator
      if (accum_rst) begin
         accum <= 0;
      end else begin
         accum <= accum_ena ? sum : accum;
      end
   end : accumulator
endmodule: convolution
