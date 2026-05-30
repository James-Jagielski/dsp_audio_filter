`timescale 1ns/1ps

module test_ideal_multiplier;

   parameter N = 5;
   parameter MAX_CLOCK_CYCLES = 10000;

   // Inputs
   logic [N-1:0] a, b;
   logic         clk, rst, ready;


   // Outputs
   logic [2*N-1:0] product;
   logic           valid;

   initial begin
      $dumpfile("ideal_multiplier.fst");
      $dumpvars(0, test_ideal_multiplier);
   end

   ideal_multiplier #(.N(N)) DUT (/*AUTOINST*/
                                  // Outputs
                                  .product              (product[2*N-1:0]),
                                  .valid                (valid),
                                  // Inputs
                                  .clk                  (clk),
                                  .rst                  (rst),
                                  .ready                (ready),
                                  .a                    (a[N-1:0]),
                                  .b                    (b[N-1:0]));

   tb_driver_multiply #(.N(N), .MAX_CLOCK_CYCLES(MAX_CLOCK_CYCLES))
   MULT_DRIVER (/*AUTOINST*/
      // Outputs
      .a                  (a[N-1:0]),
      .b                  (b[N-1:0]),
      .clk                (clk),
      .rst                (rst),
      .ready              (ready),
      // Inputs
      .product            (product[2*N-1:0]),
      .valid              (valid));

endmodule
