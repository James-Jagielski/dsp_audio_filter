`default_nettype none
`timescale 1ns/1ps
// N cycle multiplier for signed numbers via Booth's algorithm

// Follows team25 multiplication interface

module booth_multiplier(/*AUTOARG*/
   // Outputs
   product, valid,
   // Inputs
   a, b, clk, ready, rst
   );

   parameter N = 64;

   input wire signed [N-1:0] a, b;
   input wire                ready, rst, clk;

   output logic signed [2*N-1:0] product;
   output logic              valid;

   logic [N-1:0] accumulator_in, multiplier_in, multiplicand;
   logic         prev_lsb_in;

   logic [$clog2(N):0] count;

   assign product = {accumulator_out, multiplier_out};
   always_ff @(posedge clk) begin
      if (rst) begin
         /*AUTORESET*/
         // Beginning of autoreset for uninitialized flops
         accumulator_in <= {N{1'b0}};
         count <= {(1+($clog2(N))){1'b0}};
         multiplicand <= {N{1'b0}};
         multiplier_in <= {N{1'b0}};
         prev_lsb_in <= 1'h0;
         // End of automatics
      end else begin
         if (ready) begin
            count <= N-1;
            multiplier_in <= a;
            multiplicand <= b;
            prev_lsb_in <= 0;
            accumulator_in <= 0;
         end else begin
            if (~valid) begin
               count <= count - 1;
               multiplier_in <= multiplier_out;
               accumulator_in <= accumulator_out;
               prev_lsb_in <= prev_lsb_out;
            end
         end
      end
   end // always_ff @ (posedge clk)
   always_comb valid = count == 0;

   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   logic signed [N-1:0] accumulator_out;        // From booth of booth_stage_radix2.v
   logic signed [N-1:0] multiplicand_out;       // From booth of booth_stage_radix2.v
   logic signed [N-1:0] multiplier_out;         // From booth of booth_stage_radix2.v
   logic                prev_lsb_out;           // From booth of booth_stage_radix2.v
   // End of automatics

   booth_stage_radix2 #(.N(N)) booth (.multiplicand_in  (multiplicand),
                                      /*AUTOINST*/
                                      // Outputs
                                      .multiplicand_out (multiplicand_out[N-1:0]),
                                      .multiplier_out   (multiplier_out[N-1:0]),
                                      .accumulator_out  (accumulator_out[N-1:0]),
                                      .prev_lsb_out     (prev_lsb_out),
                                      // Inputs
                                      .multiplier_in    (multiplier_in[N-1:0]),
                                      .accumulator_in   (accumulator_in[N-1:0]),
                                      .prev_lsb_in      (prev_lsb_in));



endmodule : booth_multiplier
