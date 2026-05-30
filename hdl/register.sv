`default_nettype none
`timescale 1ns/1ps

module register(/*AUTOARG*/
   // Outputs
   out,
   // Inputs
   clk, ena, in, rst
   );
   parameter N=64;
   output logic [N-1:0] out;

   input logic [N-1:0]  in;
   input logic          clk, rst, ena;

   always_ff @(posedge clk) begin
      if (rst) begin
         out <= 0;
      end else if (ena) begin
         out <= in;
      end else begin
         out <= out;
      end
   end
endmodule
