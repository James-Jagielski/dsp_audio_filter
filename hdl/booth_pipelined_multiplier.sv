`default_nettype none
`timescale 1ns/1ps

module booth_pipelined_multiplier(/*AUTOARG*/
   // Outputs
   frame, product, valid,
   // Inputs
   a, b, clk, ena, ready, rst
   );
   parameter N = 64;
   localparam NSTAGES = N;

   input logic clk, rst, ena, ready;
   input logic [N-1:0] a, b;

   output logic [$clog2(NSTAGES)-1:0] frame;
   output logic signed [2*N-1:0]      product;
   output logic                       valid;

   always_ff @(posedge clk) begin : frame_counter
      if (rst) begin
         frame <= 0;
      end else if (ena) begin
         frame <= (frame+1 == NSTAGES) ? 0 : frame+1;
      end
   end : frame_counter

   // Handle the multiplication pipeline
   logic [NSTAGES*N-1:0] accumulator_ins,   multiplicand_ins,   multiplier_ins,
                         accumulator_outs,  multiplicand_outs,  multiplier_outs;
   logic [NSTAGES-1:0]   prev_lsb_ins, prev_lsb_outs;

   // Input
   assign prev_lsb_ins[0]         = 0;
   assign accumulator_ins[N-1:0]  = 0;
   assign multiplier_ins[N-1:0]   = a; // Input
   assign multiplicand_ins[N-1:0] = b; // Input

   // Mappings
   assign accumulator_ins [N*NSTAGES-1:N] = accumulator_outs [(N-1)*NSTAGES-1:0];
   assign multiplicand_ins[N*NSTAGES-1:N] = multiplicand_outs[(N-1)*NSTAGES-1:0];
   assign multiplier_ins  [N*NSTAGES-1:N] = multiplier_outs  [(N-1)*NSTAGES-1:0];
   assign prev_lsb_ins[N-1:1] = prev_lsb_outs[N-2:0];
   
   // Output
   assign product = {accumulator_outs[NSTAGES*N-1-:N], multiplier_outs[NSTAGES*N-1-:N]};

   // Pass ready/valid signal
   wire [NSTAGES:0] ready_valid;
   assign ready_valid[0] = ready;
   assign valid          = ready_valid[N];

   generate
      genvar i;
      for (i = 0; i < NSTAGES; i = i+1) begin : pipeline
         register #(.N(1)) ready_valid_reg
           (.in(ready_valid[i]),
            .out(ready_valid[i+1]),
            /*AUTOINST*/
            // Inputs
            .clk                        (clk),
            .rst                        (rst),
            .ena                        (ena));
         
         booth_stage_radix2_with_reg #(.N(N)) booth
           (// Outputs
            .multiplicand_out           (multiplicand_outs[(i*N)+:N]),
            .multiplier_out             (multiplier_outs[(i*N)+:N]),
            .accumulator_out            (accumulator_outs[(i*N)+:N]),
            .prev_lsb_out               (prev_lsb_outs[i]),
            // Inputs
            .multiplicand_in            (multiplicand_ins[(i*N)+:N]),
            .multiplier_in              (multiplier_ins[(i*N)+:N]),
            .accumulator_in             (accumulator_ins[(i*N)+:N]),
            .prev_lsb_in                (prev_lsb_ins[i]),
            /*AUTOINST*/
            // Inputs
            .clk                        (clk),
            .rst                        (rst),
            .ena                        (ena));
      end : pipeline
   endgenerate
endmodule
