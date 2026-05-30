`default_nettype none
`timescale 1ns/1ps

module shift_register(/*AUTOARG*/
   // Outputs
   out,
   // Inputs
   clk, ena, in, rst
   );
   parameter N=64;
   parameter NSTAGES=4;

   output logic [N-1:0] out;
   input logic [N-1:0]  in;
   input logic          clk, rst, ena;

   wire [N*NSTAGES-1:0] outs, ins;
   assign ins[NSTAGES*N-1:N] = outs[(NSTAGES-1)*N-1:0];
   assign ins[N-1:0] = in;
   assign out = outs[(N*NSTAGES)-1 : N*(NSTAGES-1)];

   generate
      genvar i;
      for (i = 0; i < NSTAGES; i = i + 1) begin : register_
         register #(.N(N)) register (.out (outs[i*N +: N]),
                                     .in  (ins[i*N +: N]),
                                     /*AUTOINST*/
                                     // Inputs
                                     .clk               (clk),
                                     .rst               (rst),
                                     .ena               (ena));
      end : register_
   endgenerate
endmodule
