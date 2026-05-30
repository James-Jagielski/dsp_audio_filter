`default_nettype none
`timescale 1ns/1ps

// FIR filter module
// Currently does not have saturation.
module fir_filter(/*AUTOARG*/
   // Outputs
   fir_out,
   // Inputs
   clk, conv_ready, ena, rst, sample_in
   );
   // Vector and shift amount for saturation
   parameter FIR_VECTOR = "my_fir_vector.memh";
   parameter FILTER_SHIFT_AMOUNT = 16;

   parameter NSAMPLES = 48;
   parameter SAMPLE_WIDTH = 16;

   localparam NSAMPLE_SEL_BUS = $clog2(NSAMPLES);
   localparam NCONV_OUTPUT = $clog2(NSAMPLES) + 2*SAMPLE_WIDTH;

   input wire [SAMPLE_WIDTH-1:0] sample_in;
   input wire                    clk, rst, ena,
                                 conv_ready; // this lr_clk run through an edge detector

   output logic [SAMPLE_WIDTH-1:0] fir_out;

   // output logic [SAMPLE_WIDTH-1:0] fir_out; // For when we get saturation

   always_ff @(posedge clk) begin : output_buffer
      if (rst) begin
         fir_out <= 0;
      end else if (~ena) begin
         fir_out <= 0;
      end else if (conv_ready) begin
         fir_out <= conv_out_saturate;
      end
   end : output_buffer

   logic [NCONV_OUTPUT-1:0] conv_out_shifted;
   logic [SAMPLE_WIDTH-1:0] conv_out_saturate;
   always_comb begin
      conv_out_shifted = (conv_out >>> FILTER_SHIFT_AMOUNT);
   end
   assign conv_out_saturate = conv_out_shifted[SAMPLE_WIDTH-1:0];


   // For the vectors
   wire [NSAMPLE_SEL_BUS-1:0] sample_sel;
   wire [SAMPLE_WIDTH-1:0]    impulse;
   logic [SAMPLE_WIDTH-1:0]   sample;

   logic [SAMPLE_WIDTH*NSAMPLES-1:0] shift_reg;
   always_comb sample = shift_reg[SAMPLE_WIDTH*sample_sel+:SAMPLE_WIDTH];
   always_ff @(posedge clk) begin : shift_reg_tap
      if (rst) begin
         shift_reg <= 0;
      end else if (conv_ready) begin
         shift_reg <= {shift_reg[SAMPLE_WIDTH*(NSAMPLES-1)-1:0], sample_in};
      end
   end : shift_reg_tap

   // shift_register_tap #(.N(SAMPLE_WIDTH), .NSTAGES(NSAMPLES)) audio_buffer
   //   (.tap (sample_sel),
   //    .out (sample),
   //    .in  (sample_in),
   //    .ena (conv_ready),
   //    .clk (clk),
   //    .rst (rst));

   block_rom_async #(.WIDTH(SAMPLE_WIDTH), .LENGTH(NSAMPLES), .INIT(FIR_VECTOR)) fir_vector
     (.addr (sample_sel),
      .data (impulse),
      .clk  (clk));

   wire [NCONV_OUTPUT-1:0]    conv_out;
   wire                       conv_valid;
   convolution #(.NSAMPLES(NSAMPLES), .NINPUT(SAMPLE_WIDTH)) convolver
     (// Outputs
      .sample_sel (sample_sel),
      .conv_out   (conv_out),
      .conv_valid (conv_valid),
      // Inputs
      .sample_a   (sample),
      .sample_b   (impulse),
      .clk        (clk),
      .rst        (rst),
      .conv_ready (conv_ready));

endmodule
