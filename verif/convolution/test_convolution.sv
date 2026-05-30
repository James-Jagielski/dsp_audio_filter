`default_nettype none
`timescale 1ns/1ps

module test_convolution;

   initial begin
      $dumpfile("convolution.fst");
      $dumpvars(0, test_convolution);
   end
   
   parameter NINPUT = 16;
   parameter NSAMPLES = 48;

   localparam NOUTPUT = $clog2(NSAMPLES) + 2*NINPUT; // Output bus width
   localparam NSAMPLE_BUS = $clog2(NSAMPLES);
   
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire                 clk;                    // From TB_DRIVER of tb_driver_convolution.v
   logic [NOUTPUT-1:0]  conv_out;               // From DUT of convolution.v
   wire                 conv_ready;             // From TB_DRIVER of tb_driver_convolution.v
   logic                conv_valid;             // From DUT of convolution.v
   wire                 rst;                    // From TB_DRIVER of tb_driver_convolution.v
   wire [NINPUT-1:0]    sample_a;               // From TB_DRIVER of tb_driver_convolution.v
   wire [NINPUT-1:0]    sample_b;               // From TB_DRIVER of tb_driver_convolution.v
   logic [NSAMPLE_BUS-1:0] sample_sel;          // From DUT of convolution.v
   // End of automatics

   convolution #(.NINPUT(NINPUT), .NSAMPLES(NSAMPLES)) DUT
     (/*AUTOINST*/
      // Outputs
      .sample_sel                       (sample_sel[NSAMPLE_BUS-1:0]),
      .conv_out                         (conv_out[NOUTPUT-1:0]),
      .conv_valid                       (conv_valid),
      // Inputs
      .sample_a                         (sample_a[NINPUT-1:0]),
      .sample_b                         (sample_b[NINPUT-1:0]),
      .clk                              (clk),
      .rst                              (rst),
      .conv_ready                       (conv_ready));

   tb_driver_convolution #(.NINPUT(NINPUT), .NSAMPLES(NSAMPLES)) TB_DRIVER
     (/*AUTOINST*/
      // Outputs
      .sample_a                         (sample_a[NINPUT-1:0]),
      .sample_b                         (sample_b[NINPUT-1:0]),
      .clk                              (clk),
      .rst                              (rst),
      .conv_ready                       (conv_ready),
      // Inputs
      .sample_sel                       (sample_sel[NSAMPLE_BUS-1:0]),
      .conv_out                         (conv_out[NOUTPUT-1:0]),
      .conv_valid                       (conv_valid));

endmodule: test_convolution
