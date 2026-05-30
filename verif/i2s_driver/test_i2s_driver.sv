`timescale 1ns/1ps

module test_i2s_driver;

    parameter CLK_HZ = 12_000_000;
    parameter CLK_PERIOD_NS = (1_000_000_000/CLK_HZ);

    parameter MAX_CLOCK_CYCLES = 10000;

    logic m_clk, rst, sda_rx;
    logic [15:0] rsamp_tx, lsamp_tx;

    wire s_clk, lr_clk, offset_lr_clk, sda_tx;
    wire [15:0] rsamp_rx, lsamp_rx;

    i2s_driver DUT (.m_clk(m_clk),
                    .s_clk(s_clk),
                    .lr_clk(lr_clk),
                    .offset_lr_clk(offset_lr_clk),
                    .rst(rst),
                    .sda_rx(sda_rx),
                    .sda_tx(sda_tx),
                    .rsamp_rx(rsamp_rx),
                    .rsamp_tx(rsamp_tx),
                    .lsamp_rx(lsamp_rx),
                    .lsamp_tx(lsamp_tx));

    always #(CLK_PERIOD_NS/2.0) m_clk = ~m_clk;
    
    initial begin
        $dumpfile("i2s_driver.fst");
        $dumpvars(0, DUT);

        m_clk = 0;
        rst = 1;
        sda_rx = 0;
        repeat (2) @(posedge m_clk);

        rst = 0;
        repeat (8) @(posedge m_clk);
        repeat (32) @(posedge m_clk);

        sda_rx = 1;
        repeat (32) @(posedge m_clk);

        sda_rx = 0;
        repeat (32) @(posedge m_clk);

        sda_rx = 1;
        repeat (32) @(posedge m_clk);

        sda_rx = 0;
        repeat (256) @(posedge m_clk);

        sda_rx = 1;
        repeat (512) @(posedge m_clk);

        $display("Finished test");
        $finish;
    end

    always_ff @(posedge m_clk) begin
        if (rst) begin
            lsamp_tx <= 0;
            rsamp_tx <= 0;
        end else begin
            if(offset_lr_clk) begin
                lsamp_tx <= lsamp_rx;
            end else begin
                rsamp_tx <= rsamp_rx;
            end
        end
    end

endmodule