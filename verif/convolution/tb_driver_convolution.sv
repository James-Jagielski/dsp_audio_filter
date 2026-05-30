`default_nettype none
`timescale 1ns/1ps

`ifndef TESTBENCH_ROOT
`define TESTBENCH_ROOT "foobar"
`endif

module tb_driver_convolution (
   /*AUTOARG*/
   // Outputs
   clk, conv_ready, rst, sample_a, sample_b,
   // Inputs
   conv_out, conv_valid, sample_sel
   );

   parameter MAX_CLOCK_CYCLES = 10000;
   parameter CLOCK_PERIOD = 10; // Arbitrary

   parameter NSAMPLES = 64; // Samples to convolve
   parameter NINPUT = 16; // Input bus width

   localparam NOUTPUT = $clog2(NSAMPLES) + 2*NINPUT; // Output bus width
   localparam NSAMPLE_BUS = $clog2(NSAMPLES);

   output logic [NINPUT-1:0] sample_a, sample_b;
   output logic              clk, rst, conv_ready;

   input wire [NSAMPLE_BUS-1:0] sample_sel;
   input wire [NOUTPUT-1:0]     conv_out;
   input wire                   conv_valid;

    // Driver state (helps comprehend waves)
   typedef enum int {RESET,
                     SIGNAL_READY,
                     WAIT_VALID,
                     CHECK_OUTPUT} driver_state_t;
   driver_state_t driver_state;

   // Test vectors
   logic [NINPUT-1:0]  sample_a_vector [NSAMPLES-1:0];
   logic [NINPUT-1:0]  sample_b_vector [NSAMPLES-1:0];
   // Too large but it needs to be pre-defined size.
   logic [NOUTPUT-1:0] conv_out_vector [NSAMPLES-1:0];

   // Generate clock
   always #(CLOCK_PERIOD/2) clk <= ~clk;

   // Samples to convolve
   assign sample_a = sample_a_vector[sample_sel];
   assign sample_b = sample_b_vector[sample_sel];

   initial begin
      // Load vectors, hard coded for now, maybe later when the sim script
      // supports +args it can not be.
      $display({`TESTBENCH_ROOT, "/", "simple_sample_a.memb"});

      // // Simple vector made by hand
      // $readmemb({`TESTBENCH_ROOT, "/", "simple_sample_a.memb"}, sample_a_vector);
      // $readmemb({`TESTBENCH_ROOT, "/", "simple_sample_b.memb"}, sample_b_vector);
      // $readmemb({`TESTBENCH_ROOT, "/", "simple_conv_out.memb"}, conv_out_vector);

      // Random vector
      $readmemb({`TESTBENCH_ROOT, "/", "random1_sample_a.memb"}, sample_a_vector);
      $readmemb({`TESTBENCH_ROOT, "/", "random1_sample_b.memb"}, sample_b_vector);
      $readmemb({`TESTBENCH_ROOT, "/", "random1_conv_out.memb"}, conv_out_vector);

      clk        = 0;
      rst        = 0;
      conv_ready = 0;

      reset();
      signal_ready();
      wait_valid();
      check_output();
      reset();

      print_header("Test Passed!");
      $finish;
   end

   task reset;
      int num_errors = 0;

      driver_state = RESET;
      print_header("Begin Reset");

      rst = 1;
      conv_ready = 0;
      @(posedge clk);

      rst = 0;
      @(posedge clk);

      $display("conv_valid = %b", conv_valid);
      assert (conv_valid) else begin
         $display("%s%b", EXPECTED, 1);
         num_errors = num_errors + 1;
      end

      check_test_failed(num_errors);

      print_header("End Reset");
   endtask: reset

   task signal_ready;
      int num_errors = 0;

      driver_state = SIGNAL_READY;
      print_header("Begin Signal Ready");

      rst        = 0;
      conv_ready = 1;

      @(posedge clk);
      conv_ready = 0;
      @(posedge clk);

      $display("conv_valid = %b", conv_valid);
      assert (~conv_valid) else begin
         $display("%s%b", EXPECTED, 0);
         num_errors = num_errors + 1;
      end

      check_test_failed(num_errors);

      print_header("End Signal Ready");
   endtask: signal_ready

   task wait_valid;
      driver_state = WAIT_VALID;
      print_header("Begin Wait Valid");

      rst        = 0;
      conv_ready = 0;

      // If this doesn't work it will time out
      @(posedge conv_valid);

      $display("conv_valid received.");

      print_header("End Wait Valid");
   endtask: wait_valid

   task check_output;
      int num_errors = 0;

      driver_state = CHECK_OUTPUT;
      print_header("Begin Check Output");

      $display("conv_out = %h", conv_out);
      assert (conv_out == conv_out_vector[0]) else begin
         $display("%s%h", EXPECTED, conv_out_vector[0]);
         num_errors = num_errors + 1;
      end

      check_test_failed(num_errors);

      print_header("End Check Output");
   endtask: check_output

   initial begin
      repeat (MAX_CLOCK_CYCLES) @(posedge clk);
      $display("Test did not finish after %d clock cycles", MAX_CLOCK_CYCLES);
      $finish;
   end

   // FIXME dih: considering how these are copied into all testbenches, maybe
   // we should have a verification library.
   string    EXPECTED = "        Expected: ";

   function int print_header(string s);
      $display("");
      $display("################################################");
      $display(s);
      $display("################################################");
      $display("");
      return 0;
   endfunction : print_header

   task check_test_failed(int num_errors);
      if (num_errors > 0) begin
         print_header("Test Failed");
         $display("%d errors", num_errors);
         $finish;
      end
   endtask

endmodule: tb_driver_convolution
