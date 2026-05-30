`default_nettype none
`timescale 1ns/1ps

module booth_stage_radix2_with_reg(/*AUTOARG*/
   // Outputs
   accumulator_out, multiplicand_out, multiplier_out, prev_lsb_out,
   // Inputs
   accumulator_in, clk, ena, multiplicand_in, multiplier_in, prev_lsb_in, rst
   );

   parameter N=64;
   input wire clk, rst, ena;

   /*AUTOINPUT*/
   // Beginning of automatic inputs (from unused autoinst inputs)
   input logic signed [N-1:0] accumulator_in;   // To booth of booth_stage_radix2.v
   input logic signed [N-1:0] multiplicand_in;  // To booth of booth_stage_radix2.v
   input logic signed [N-1:0] multiplier_in;    // To booth of booth_stage_radix2.v
   input logic          prev_lsb_in;            // To booth of booth_stage_radix2.v
   // End of automatics

   output logic signed [N-1:0] accumulator_out;
   output logic signed [N-1:0] multiplicand_out;
   output logic signed [N-1:0] multiplier_out;
   output logic                prev_lsb_out;

   wire [N-1:0] multiplicand, multiplier, accumulator;
   wire         prev_lsb;
   always_ff @(posedge clk) begin
      if (rst) begin
         /*AUTORESET*/
         // Beginning of autoreset for uninitialized flops
         accumulator_out <= {N{1'b0}};
         multiplicand_out <= {N{1'b0}};
         multiplier_out <= {N{1'b0}};
         prev_lsb_out <= 1'h0;
         // End of automatics
      end else if (ena) begin
         accumulator_out  <= accumulator;
         multiplier_out   <= multiplier;
         multiplicand_out <= multiplicand;
         prev_lsb_out     <= prev_lsb;
      end
   end

   booth_stage_radix2 #(.N(N)) booth(.multiplicand_out(multiplicand),
                                     .multiplier_out  (multiplier),
                                     .accumulator_out (accumulator),
                                     .prev_lsb_out    (prev_lsb),
                                     /*AUTOINST*/
                                     // Inputs
                                     .multiplicand_in   (multiplicand_in[N-1:0]),
                                     .multiplier_in     (multiplier_in[N-1:0]),
                                     .accumulator_in    (accumulator_in[N-1:0]),
                                     .prev_lsb_in       (prev_lsb_in));
endmodule
