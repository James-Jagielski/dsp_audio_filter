`default_nettype none
`timescale 1ns/1ps

// Defined in command file; here to silence linter
`ifndef HDL_ROOT
`define HDL_ROOT "foobar"
`endif

`ifndef TESTBENCH_ROOT
`define TESTBENCH_ROOT "foobar"
`endif

module test_fir_filter;

   // For the band pass filter "band_pass_50_8000.memh"
   parameter MEM_ROOT = {`HDL_ROOT, "/mems"};
   parameter FIR_VECTOR = {MEM_ROOT, "/", "band_pass_50_8000.memh"};
   parameter FILTER_SHIFT_AMOUNT = 16;

   parameter NSAMPLES = 48;
   parameter SAMPLE_WIDTH = 16;

   parameter CLK_HZ = 12_000_000;
   parameter CLK_PERIOD_NS = (1_000_000_000/CLK_HZ);

   initial begin
      $dumpfile("fir_filter.fst");
      $dumpvars(0, test_fir_filter);
   end

   wire  [SAMPLE_WIDTH-1:0] fir_out;

   logic [SAMPLE_WIDTH-1:0] sample_in;
   logic                    rst, ena, conv_ready;

   logic clk;

   always #(CLK_PERIOD_NS/2) clk <= ~clk;

   int max_clock_cycles = 10000;

   initial begin
      int clock_cycle = 0;
      clk = 0;

      forever begin
         @(posedge clk);
         clock_cycle = clock_cycle + 1;
         if (clock_cycle == max_clock_cycles) begin
            $display("Test did not finish after %d clock cycles", max_clock_cycles);
            $finish;
         end
      end
   end

   initial begin : drive_signals
      $timeformat(-9, 0, " ns", 10);
      reset();
      run_sample();
   end : drive_signals

   initial begin : compare_result
      @(negedge rst);
      @(posedge clk);
      fir_checker();
   end : compare_result

   task automatic fir_checker;
      int num_errors = 0;
      int max_errors = 10;

      int no_sync_timeout = 10; // If no match after 10 cycles end simulation
      int hdl_vector_sync = 0;

      int len_output = 42799; // voice with noise input, filtered
      bit [SAMPLE_WIDTH-1:0] fir_out_vec [42799-1:0];

      $readmemh({`TESTBENCH_ROOT, "/vectors/", "voice-with-noise-filtered.memh"}, fir_out_vec);

      while (fir_out_vec[0] != fir_out) begin
         $display("Waiting on conv_out sync, %d tries left", no_sync_timeout);
         @(posedge conv_ready);
         if (no_sync_timeout == 0) begin
            print_header("Test Failed");
            $display("Could not sync HDL output and vector");
         end
         no_sync_timeout = no_sync_timeout - 1;
      end

      print_header("HDL and output vector synced");

      for (int i=0; i < len_output; i = i+1) begin
         $display("%t    fir_out=0x%4h", $time, fir_out);
         assert (fir_out_vec[i] == fir_out) else begin
            $display("%20s 0x%4h", "Expected", fir_out_vec[i]);
            num_errors = num_errors + 1;
         end
         if (num_errors >= max_errors) begin
            check_test_failed(num_errors);
         end
         @(posedge conv_ready);
      end

      $display("Output vector finished!");
      print_header("Test Passed!");
      $finish;
   endtask : fir_checker

   task reset;
      print_header("Begin Reset");

      rst = 1;
      ena = 0;
      conv_ready = 0;
      sample_in = 0;

      repeat (2) @(posedge clk);
      rst = 0;
      ena = 1;
      conv_ready = 0;

      print_header("End Reset");
   endtask: reset

   task automatic run_sample;
      // Really need plus args rn
      int len_input = 42752; // voice with noise input
      bit [SAMPLE_WIDTH-1:0] sample_in_vec [42752-1:0];

      print_header("Starting send data to FIR filter");

      max_clock_cycles = max_clock_cycles + len_input*256;
      // max_clock_cycles = max_clock_cycles + 100*256;
      $display("Increasing max_clock_cycles to %d", max_clock_cycles);

      $readmemh({`TESTBENCH_ROOT, "/vectors/", "voice-with-noise-input.memh"}, sample_in_vec);

      rst = 0;
      ena = 1;
      conv_ready = 0;

      for (int i = 0; i < len_input; i = i+1) begin
         sample_in = sample_in_vec[i];
         $display("%t sample_in=0x%h, (%1d/%1d)", $time, sample_in, i, len_input);
         conv_ready = 1;
         @(posedge clk);

         conv_ready = 0;
         repeat (255) @(posedge clk);
      end

      print_header("Finished sending data to FIR filter");
   endtask: run_sample

   fir_filter #(.FIR_VECTOR(FIR_VECTOR),
                .FILTER_SHIFT_AMOUNT(FILTER_SHIFT_AMOUNT),
                .NSAMPLES(NSAMPLES),
                .SAMPLE_WIDTH(SAMPLE_WIDTH))
   DUT
     (/*AUTOINST*/
      // Outputs
      .fir_out                          (fir_out[SAMPLE_WIDTH-1:0]),
      // Inputs
      .sample_in                        (sample_in[SAMPLE_WIDTH-1:0]),
      .clk                              (clk),
      .rst                              (rst),
      .ena                              (ena),
      .conv_ready                       (conv_ready));

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

endmodule
