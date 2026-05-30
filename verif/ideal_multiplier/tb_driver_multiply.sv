`timescale 1ns/1ps

// Testbench driver for multipliers conforming to the Team25 multiplier
// interface

module tb_driver_multiply (/*AUTOARG*/
                           // Outputs
                           a, b, clk, ready, rst,
                           // Inputs
                           product, valid
                           );

   parameter CLOCK_PERIOD = 10;
   parameter N = 5;
   parameter MAX_CLOCK_CYCLES = 10000;
   string    EXPECTED = "        Expected: ";

   // Driver state machine
   typedef enum int {TEST_RESET,
                     TEST_HANDSHAKE,
                     TEST_OUTPUT_HOLD,
                     TEST_FIVE_BIT_NUMS} driver_state_t;


   output logic signed [N-1:0] a, b;
   output logic                clk, rst, ready;

   input logic signed [2*N-1:0] product;
   input logic                  valid;

   // Generate clock
   always #(CLOCK_PERIOD/2) clk <= ~clk;

   initial begin
      repeat (MAX_CLOCK_CYCLES) @(posedge clk);
      $display("Test did not finish after %d clock cycles", MAX_CLOCK_CYCLES);
      $finish;
   end

   logic [2*N-1:0] expected_product;
   always_comb expected_product = a*b;


   // Non-synthesizable driver logic
   driver_state_t driver_state;
   initial begin
      // Testbench start
      print_header("begin multiplier testbench driver");
      clk   = 0;
      a     = 0;
      b     = 0;
      ready = 0;
      rst   = 0;

      test_reset();
      test_handshake();
      test_output_hold();
      test_five_bit_nums();
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
      assert(valid == 1) else begin
         $display("%s%h", EXPECTED, 1);
         num_errors = num_errors + 1;
      end

      check_test_failed(num_errors);
   endtask : test_reset

   task automatic test_handshake();
      int num_errors = 0;

      driver_state = TEST_HANDSHAKE;

      print_header("Test Handshake");
      a = 1;
      b = 1;
      ready = 1;
      @(posedge clk);
      #1 ready = 0;


      @(posedge valid);
      $display("%b", valid);
      @(posedge clk);
      $display("Received valid from handshake");

      $display("product = 0x%h", product);
      assert (a*b == product) else begin
         $display("%s0x%h", EXPECTED, a*b);
         num_errors = num_errors + 1;
      end

      check_test_failed(num_errors);
   endtask : test_handshake

   task automatic test_output_hold();
      int clocks_to_hold = 100;
      int num_errors = 0;
      logic prev_valid;
      logic [2*N-1:0] prev_product;

      driver_state = TEST_OUTPUT_HOLD;

      print_header("Test Output Hold");
      repeat (clocks_to_hold) begin
         prev_valid = valid;
         prev_product = product;
         @(posedge clk);

         assert (prev_valid == valid) else begin
            $display("Valid changed, should hold when no handshake initialized.");
            num_errors = num_errors + 1;
         end
         assert (prev_product == product) else begin
            $display("Product changed, should hold when no handshake initialized.");
            num_errors = num_errors + 1;
         end
      end // repeat (clocks_to_hold)

      check_test_failed(num_errors);
      $display("Successfully held %d clock cycles.", clocks_to_hold);

   endtask : test_output_hold

   task automatic test_five_bit_nums();
      int num_errors = 0;

      driver_state = TEST_FIVE_BIT_NUMS;

      print_header("Test Five Bit Nums");

      // a and b are 5 bit, don't cause an infinite loop
      for (int x = -16; x <= 15; x = x + 1) begin
         for (int y = -16; y <= 15; y = y + 1) begin
            #1;
            a = x[N-1:0];
            b = y[N-1:0];

            ready = 1;
            @(posedge clk);
            #1 ready = 0;

            @(posedge valid);
            #1;
            $display("a=%h    b=%h,    product=%h, in decimal a=%d    b=%d    product=%d",
                     a, b, product, a, b, product);
            assert (expected_product == product) else begin
               $display("%sproduct=%h", EXPECTED, a*b);
               num_errors = num_errors + 1;
            end
         end // for (b = -16; b <= 15; b = b + 1)
      end // for (a = -16; a <= 15; a = a + 1)

      check_test_failed(num_errors);
      $display("Tested times table from -16 to 15");

   endtask : test_five_bit_nums

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


endmodule : tb_driver_multiply
