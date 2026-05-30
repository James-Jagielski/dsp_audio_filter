`default_nettype none
`timescale 1ns/1ps
// For verification purposes.

module ideal_pipelined_multiplier(/*AUTOARG*/
   // Outputs
   frame, product, valid,
   // Inputs
   a, b, clk, ena, ready, rst
   );

   parameter N = 64;
   parameter NSTAGES = N;

   input logic clk, rst, ena, ready;
   input logic [N-1:0] a, b;

   output logic [$clog2(NSTAGES)-1:0] frame;
   output logic signed [2*N-1:0]      product;
   output logic                       valid;


   always_ff @(posedge clk) begin
      if (rst) begin
         /*AUTORESET*/
         // Beginning of autoreset for uninitialized flops
         frame <= {(1+($clog2(NSTAGES)-1)){1'b0}};
         // End of automatics
      end else if (ena) begin
         frame <= (frame == NSTAGES-1) ? 0 : frame + 1;
      end
   end // always_ff @ (posedge clk)

   wire signed [N-1:0] mult_a, mult_b;
   shift_register #(.NSTAGES(NSTAGES), .N(N)) buffer_a
     (.in(a),
      .out(mult_a),
      /*AUTOINST*/
      // Inputs
      .clk                              (clk),
      .rst                              (rst),
      .ena                              (ena));

   shift_register #(.NSTAGES(NSTAGES), .N(N)) buffer_b
     (.in(b),
      .out(mult_b),
      /*AUTOINST*/
      // Inputs
      .clk                              (clk),
      .rst                              (rst),
      .ena                              (ena));

   shift_register #(.NSTAGES(NSTAGES), .N(1)) buffer_ready
     (.in(ready),
      .out(valid),
      /*AUTOINST*/
      // Inputs
      .clk                              (clk),
      .rst                              (rst),
      .ena                              (ena));

   always_comb product = mult_a * mult_b;


endmodule
