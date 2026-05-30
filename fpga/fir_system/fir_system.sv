`default_nettype none
`timescale 1ns/1ps

// Defined in command file; here to silence linter
`ifndef HDL_ROOT
`define HDL_ROOT "foobar"
`endif

module fir_system (
    // Outputs
    leds, ad_lr_clk, da_lr_clk, ad_s_clk, da_s_clk, sda_tx,

    // Debug Outputs
    high, ad_clk, da_clk,

    // Inputs
    buttons, clk, sda_rx
    );

    // Parameters
    parameter MEM_ROOT = {`HDL_ROOT, "/mems/"};
    parameter FIR_VECTOR = {MEM_ROOT, "band_pass_50_8000.memh"};
    parameter NSAMPLES = 48;
    parameter SAMPLE_WIDTH = 16;
    parameter FILTER_SHIFT_AMOUNT = 16;

    // CMOD A7
    input wire [1:0]   buttons;
    input wire         clk;
    output logic [1:0] leds;
    output logic       high;

    // PMOD i2s2
    output logic ad_clk, da_clk;
    logic m_clk;
    output logic ad_lr_clk;
    output logic da_lr_clk;
    logic lr_clk;
    output logic ad_s_clk;
    output logic da_s_clk;
    logic s_clk;
    output logic sda_tx;
    input wire   sda_rx;

    // Buttons
    logic rst;
    logic loopback;
    always_comb rst = buttons[0];
    always_comb leds[0] = loopback;

    edge_detector button_edge (
      .pos_edge(button_1_positive),
      .clk(m_clk),
      .in(buttons[1]),
      .rst(rst)
    );

    wire [15:0] lr_clk_pos, lr_clk_neg;
    edge_detector lr_data_ready (
      .pos_edge(lr_clk_pos),
      .neg_edge(lr_clk_neg),
      .clk(m_clk),
      .in(lr_clk),
      .rst(rst)
    );

    // i2s driver
    always_comb begin 
      m_clk = clk;
      da_clk = clk;
      ad_clk = clk;
      ad_lr_clk = lr_clk;
      da_lr_clk = lr_clk;
      ad_s_clk = s_clk;
      da_s_clk = s_clk;
    end
    logic [15:0] rsamp_rx, lsamp_rx;
    logic [15:0] rsamp_tx, lsamp_tx;

    always_comb begin : i2s_interface
      high = 1;
      if (loopback) begin
        rsamp_tx = rsamp_reg;
        lsamp_tx = lsamp_reg;
        fir_ena = 0;
      end else begin
        rsamp_tx = fir_r_out;
        lsamp_tx = fir_l_out;
        fir_ena = 1;
      end
    end

    i2s_driver i2s_driver (
      .m_clk    (m_clk),
      .s_clk    (s_clk),
      .lr_clk   (lr_clk),
      .rst      (rst),
      .sda_rx   (sda_rx),
      .sda_tx   (sda_tx),
      .rsamp_rx (rsamp_rx),
      .rsamp_tx (rsamp_tx),
      .lsamp_rx (lsamp_rx),
      .lsamp_tx (lsamp_tx)
    );

    // Loopback test
    logic button_1_positive;
    logic fir_ena;
    logic [15:0] rsamp_reg, lsamp_reg;
    always_ff @(posedge m_clk) begin
      if (rst) begin 
        loopback <= 0;
        rsamp_reg <= 0;
        lsamp_reg <= 0;
      end
      else begin
        if (button_1_positive) loopback <= ~loopback;
        if (loopback) begin
          rsamp_reg <= rsamp_rx;
          lsamp_reg <= lsamp_rx;
        end else begin
          rsamp_reg <= fir_r_out;
          lsamp_reg <= fir_l_out;
        end
      end
    end

    // FIR filters
    logic [15:0] fir_r_out, fir_l_out;

    fir_filter #(
      .FIR_VECTOR(FIR_VECTOR), 
      .FILTER_SHIFT_AMOUNT(16),
      .NSAMPLES(NSAMPLES),
      .SAMPLE_WIDTH(SAMPLE_WIDTH)
      ) fir_filter_l (
      .fir_out    (fir_l_out),
      .clk        (m_clk),
      .conv_ready (lr_clk_neg),
      .ena        (fir_ena),
      .rst        (rst),
      .sample_in  (lsamp_rx)
    );

    fir_filter #(
      .FIR_VECTOR(FIR_VECTOR), 
      .FILTER_SHIFT_AMOUNT(16),
      .NSAMPLES(NSAMPLES),
      .SAMPLE_WIDTH(SAMPLE_WIDTH)
      ) fir_filter_r (
      .fir_out    (fir_r_out),
      .clk        (m_clk),
      .conv_ready (lr_clk_pos),
      .ena        (fir_ena),
      .rst        (rst),
      .sample_in  (rsamp_rx)
    );

endmodule
