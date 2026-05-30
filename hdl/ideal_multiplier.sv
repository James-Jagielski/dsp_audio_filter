`default_nettype none
`timescale 1ns/1ps

// N cycle multiplier using behavioral Verilog
// Used for verification purposes, do not use in project.

module ideal_multiplier(/*AUTOARG*/
   // Outputs
   product, valid,
   // Inputs
   a, b, clk, ready, rst
   );
   parameter N = 64;
   parameter CYCLES = N;

   input logic clk, rst, ready;
   input logic signed [N-1:0] a, b;


   output logic signed [2*N-1:0] product;
   output logic                  valid;

   // Implementation of the delayed valid
   logic [$clog2(CYCLES):0] valid_delay;

   always_ff @(posedge clk) begin
      if (rst) begin
         /*AUTORESET*/
         // Beginning of autoreset for uninitialized flops
         product <= {(1+(2*N-1)){1'b0}};
         valid_delay <= {(1+($clog2(CYCLES))){1'b0}};
         // End of automatics
      end
      else begin
         if (ready) begin
            product <= a * b;
            valid_delay <= CYCLES;
         end else begin
            if (~valid) begin
               valid_delay <= valid_delay - 1;
            end
         end
      end
   end

   always_comb valid = (valid_delay == 0);

endmodule
