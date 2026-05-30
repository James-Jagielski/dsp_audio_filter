`default_nettype none
`timescale 1ns/1ps

module booth_stage_radix2(/*AUTOARG*/
   // Outputs
   accumulator_out, multiplicand_out, multiplier_out,
   // Inputs
   accumulator_in, multiplicand_in, multiplier_in, prev_lsb_in, prev_lsb_out
   );

   parameter N=64;

   output logic signed [N-1:0] multiplicand_out, multiplier_out, accumulator_out;
   output logic                prev_lsb_out;
   input  logic signed [N-1:0] multiplicand_in, multiplier_in, accumulator_in;
   input  logic                prev_lsb_in;

   logic [1:0] booth_bits;
   assign booth_bits = {multiplier_in[0], prev_lsb_in};

   logic [N:0] to_accum;
   logic [N:0] next_accum;
   always_comb begin
      case (booth_bits)
        2'b00,
        2'b11: begin
           to_accum = 0;
        end
        2'b01: begin
           to_accum = {multiplicand_in[N-1], multiplicand_in};
        end
        2'b10: begin
           to_accum = -{multiplicand_in[N-1], multiplicand_in};
        end
      endcase // case (booth_bits)
      next_accum = {accumulator_in[N-1], accumulator_in} + to_accum;
   end

   // Assign outputs
   assign multiplicand_out = multiplicand_in;
   assign prev_lsb_out = multiplier_in[0];
   assign accumulator_out = next_accum[N:1];
   assign multiplier_out = {next_accum[0], multiplier_in[N-1:1]};
endmodule
