`timescale 1ns/1ps

// Testbench driver for multipliers conforming to the Team25 multiplier
// interface

module tb_driver_pipelined_multiply (/*AUTOARG*/
                                     // Outputs
                                     a, b, clk, ena, ready, rst,
                                     // Inputs
                                     frame, product, valid
                                     );

   parameter CLOCK_PERIOD = 10;
   parameter N = 5;
   parameter MAX_CLOCK_CYCLES = 10000;
   string    EXPECTED = "        Expected: ";

   // Driver state machine
   typedef enum int {TEST_RESET,
                     TEST_FIVE_BIT_NUMS,
                     TEST_ENA} driver_state_t;


   output logic signed [N-1:0] a, b;
   output logic                clk, rst, ena, ready;

   input logic signed [2*N-1:0] product;
   input logic [7:0]            frame; // The drier has an 8 bit frame, it will be fine.
   input logic                  valid;

   // Generate clock
   always #(CLOCK_PERIOD/2) clk <= ~clk;

   initial begin
      repeat (MAX_CLOCK_CYCLES) @(posedge clk);
      $display("Test did not finish after %d clock cycles", MAX_CLOCK_CYCLES);
      $finish;
   end

   // Non-synthesizable driver logic
   driver_state_t driver_state;

   initial begin
      // Testbench start
      print_header("Begin pipelined multiplier testbench driver");
      clk   = 0;
      a     = 0;
      b     = 0;
      ready = 0;
      rst   = 0;
      ena   = 0;

      test_reset();
      test_five_bit_nums();
      test_ena();
      test_reset();

      print_header("Test Passed!");
      $finish;

   end

   task automatic test_reset();
      int num_errors = 0;

      driver_state = TEST_RESET;

      print_header("Reset Multiplier");

      rst = 1;
      repeat (2) @(posedge clk);
      rst = 0;
      repeat (2) @(posedge clk);

      $display("product = %h", product);
      assert(product == 0) else begin
         $display("%s%h", EXPECTED, 0);
         num_errors = num_errors + 1;
      end

      $display("valid = %b", valid);
      assert(valid == 0) else begin
         $display("%s%h", EXPECTED, 0);
         num_errors = num_errors + 1;
      end

      check_test_failed(num_errors);
   endtask : test_reset

   logic signed [2*N-1:0] driver_product;
   task automatic test_five_bit_nums();
      int num_errors = 0;
      int product_queue [$];


      driver_state = TEST_FIVE_BIT_NUMS;
      ena = 1;
      ready = 1;

      print_header("Test Five Bit Nums");

      // a and b are 5 bit, don't cause an infinite loop
      for (int x = -16; x < 16; x = x + 1) begin
         for (int y = -16; y < 16; y = y + 1) begin
            ready = 1;
            a = x;
            b = y;
            product_queue.push_front(x*y);
            @(posedge clk);

            if (valid) begin
               driver_product = product_queue.pop_back();
               $display("frame=%h,    product=%h",
                        frame, product);

               assert (driver_product == product) else begin
                  $display("%sproduct=%h", EXPECTED, driver_product);
                  num_errors = num_errors + 1;
               end
            end // if (valid)
         end // for (int y = -16; y < 16; y = y + 1)
      end // for (int x = -16; x < 16; x = x + 1)

      check_test_failed(num_errors);
      $display("Tested times table from -16 to 15");

   endtask : test_five_bit_nums

   task test_ena;
      int num_errors = 0;
      int clocks_to_hold = 100;
      int prev_product, prev_frame, prev_valid;

      print_header("Test ENA");
      driver_state = TEST_ENA;
      ena = 0;
      #1;

      repeat (clocks_to_hold) begin
         prev_product = product;
         prev_frame = frame;
         prev_valid = valid;
         @(posedge clk);

         assert (prev_valid == valid) else begin
            $display("Valid changed, should hold");
            num_errors = num_errors + 1;
         end
         assert (prev_frame == frame) else begin
            $display("Frame changed, should hold");
            num_errors = num_errors + 1;
         end
         assert (prev_product == product) else begin
            $display("Product changed, should hold");
            num_errors = num_errors + 1;
         end
      end // repeat (clocks_to_hold)

      check_test_failed(num_errors);
      $display("Successfully held %d clock cycles.", clocks_to_hold);
   endtask : test_ena

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


endmodule : tb_driver_pipelined_multiply
