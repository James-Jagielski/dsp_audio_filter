`default_nettype none
`timescale 1ns/1ps


module pipelined_multiplier (/*AUTOARG*/
   // Outputs
   a, b, frame, leds, product,
   // Inputs
   buttons, clk
   );
   parameter N = 4;
   parameter MULTIPLY_PERIOD = 12_000_000/50;

   input wire [1:0] buttons;
   input wire       clk;

   output logic [1:0]           leds;

   // GIPO output
   // output wire [23:1]           pio; // forgive the magic number

   output wire [$clog2(N)-1:0] frame;   // Pins 1-2
   output wire [2*N-1:0]       product; // Pins 4-11
   output wire [N-1:0]         a,       // Pins 17-20
                               b;       // Pins 26-29

   // assign pio[$clog2(N):1] = frame;
   // assign pio[13:4]        = product;
   // assign pio[18:14]       = a;
   // assign pio[23:19]       = b;

   logic rst;
   always_comb rst = |buttons;

   // Create input signals of multiplier
   logic [2*N-1:0] counter;
   always_ff @(posedge clk) begin
      if (rst) begin
         counter <= 0;
      end else if (pipeline_ena) begin
         counter <= counter + 1;
      end
   end
   assign a = counter[N-1:0];
   assign b = counter[2*N-1:N];

   assign leds[0] = counter[0];

   wire pipeline_ena;
   wire [$clog2(MULTIPLY_PERIOD)-1:0] pipeline_ticks;
   assign pipeline_ticks = MULTIPLY_PERIOD-1;
   pulse_generator #(.N($clog2(MULTIPLY_PERIOD))) pipeline_ena_gen
     (.out  (pipeline_ena),
      .ena  (1),
      .ticks(pipeline_ticks),
      /*AUTOINST*/
      // Inputs
      .clk                              (clk),
      .rst                              (rst));


   booth_pipelined_multiplier #(.N(N)) multiplier
     (.ready (1'b1),
      .ena   (pipeline_ena),
      .frame (frame),
      .valid (1'b1),
      /*AUTOINST*/
      // Outputs
      .product                          (product[2*N-1:0]),
      // Inputs
      .clk                              (clk),
      .rst                              (rst),
      .a                                (a[N-1:0]),
      .b                                (b[N-1:0]));


   // Make LED output interact with product
   logic [2*N-1:0] product_abs;
   always_comb product_abs = product[N-1] ? -product : product;
   logic mult_pulse;

   logic [2*N-1:0] pwm_counter;
   always_ff @(posedge clk) begin
      if (rst) begin
         pwm_counter <= 0;
      end else begin
         pwm_counter <= pwm_counter + 1;
      end
   end
   always_comb mult_pulse = pwm_counter < product_abs;

   // assign leds[1] = mult_pulse;
   assign leds[1] = mult_pulse;

endmodule
