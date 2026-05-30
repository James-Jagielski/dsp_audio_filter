`default_nettype none
`timescale 1ns/1ps

module i2s_driver(m_clk, s_clk, lr_clk, offset_lr_clk, rst, sda_rx, sda_tx, rsamp_rx, rsamp_tx, lsamp_rx, lsamp_tx);

    input wire m_clk, rst, sda_rx;
    input wire [15:0] rsamp_tx, lsamp_tx;
    output logic s_clk, lr_clk, offset_lr_clk, sda_tx;
    output logic [15:0] rsamp_rx, lsamp_rx;

    logic [7:0] count, offset_count;

    assign s_clk = count[2];
    assign lr_clk = count[7];
    assign offset_lr_clk = offset_count[7];

    wire neg_edge, pos_edge;

    edge_detector EDGE_DET (.neg_edge(neg_edge), .pos_edge(pos_edge), .clk(m_clk), .in(s_clk), .rst(rst));

    always_ff @(posedge m_clk) begin
        if (rst) begin
            count <= 0;
            offset_count <= 248;
            rsamp_rx <= 0;
            lsamp_rx <= 0;
            sda_tx <= 0;
        end else begin
            count <= count + 1;
            offset_count <= offset_count + 1;
            if (pos_edge) begin
                if (offset_lr_clk) begin
                    rsamp_rx <= {rsamp_rx[14:0], sda_rx};
                end else begin
                    lsamp_rx <= {lsamp_rx[14:0], sda_rx};
                end
            end
            if (neg_edge) begin
                if (offset_lr_clk) begin
                    sda_tx <= rsamp_tx[15 - offset_count[6:3]];
                end else begin
                    sda_tx <= lsamp_tx[15 - offset_count[6:3]];
                end
            end
        end
    end

endmodule