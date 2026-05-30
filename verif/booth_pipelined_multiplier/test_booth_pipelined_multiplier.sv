`timescale 1ns/1ps


module test_ideal_pipelined_multiplier;

   parameter N = 5;
   parameter MAX_CLOCK_CYCLES = 10000;

   initial begin
      $dumpfile("booth_pipelined_multiplier.fst");
      $dumpvars(0, test_ideal_pipelined_multiplier);
   end

   wire [7:0] frame; // If you need more than 256 frames something is wrong

   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   logic signed [N-1:0] a;                      // From MULT_DRIVER of tb_driver_pipelined_multiply.v
   logic signed [N-1:0] b;                      // From MULT_DRIVER of tb_driver_pipelined_multiply.v
   logic                clk;                    // From MULT_DRIVER of tb_driver_pipelined_multiply.v
   logic                ena;                    // From MULT_DRIVER of tb_driver_pipelined_multiply.v
   logic signed [2*N-1:0] product;              // From DUT of booth_pipelined_multiplier.v
   logic                ready;                  // From MULT_DRIVER of tb_driver_pipelined_multiply.v
   logic                rst;                    // From MULT_DRIVER of tb_driver_pipelined_multiply.v
   logic                valid;                  // From DUT of booth_pipelined_multiplier.v
   // End of automatics
   booth_pipelined_multiplier #(.N(N))
   DUT (.frame (frame),
        /*AUTOINST*/
        // Outputs
        .product                        (product[2*N-1:0]),
        .valid                          (valid),
        // Inputs
        .clk                            (clk),
        .rst                            (rst),
        .ena                            (ena),
        .ready                          (ready),
        .a                              (a[N-1:0]),
        .b                              (b[N-1:0]));

   tb_driver_pipelined_multiply
     #(.MAX_CLOCK_CYCLES(MAX_CLOCK_CYCLES), .N(N))
   MULT_DRIVER (/*AUTOINST*/
                // Outputs
                .a                      (a[N-1:0]),
                .b                      (b[N-1:0]),
                .clk                    (clk),
                .rst                    (rst),
                .ena                    (ena),
                .ready                  (ready),
                // Inputs
                .product                (product[2*N-1:0]),
                .frame                  (frame[7:0]),
                .valid                  (valid));

endmodule
