module edge_detector(/*AUTOARG*/
   // Outputs
   neg_edge, pos_edge,
   // Inputs
   clk, in, rst
   );

   input wire clk, rst, in;
   output logic pos_edge, neg_edge;

   logic prev_in;

   always_ff @(posedge clk) begin
       if (rst) begin
          prev_in <= 0;
       end else begin
          prev_in <= in;
       end
   end

   always_comb begin
      pos_edge =  in & ~prev_in;
      neg_edge = ~in &  prev_in;
   end
   
endmodule
