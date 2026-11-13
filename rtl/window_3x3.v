// 3x3 sliding window over a row-major pixel stream.
// Output wRC = row R, column C of the window (w00 = top-left).
// valid_out is registered together with the window, so the two are aligned.
// Latency: window for pixel k appears 1 clock after pixel k is accepted.
module window_3x3 #(
    parameter DW = 8,
    parameter W  = 64,
    parameter H  = 64
)(
    input  wire          clk,
    input  wire          rst_n,
    input  wire          en,
    input  wire [DW-1:0] pix_in,
    output reg           valid_out,
    output reg  [DW-1:0] w00, w01, w02,
    output reg  [DW-1:0] w10, w11, w12,
    output reg  [DW-1:0] w20, w21, w22
);
    localparam CW = $clog2(W);
    localparam RW = $clog2(H);

    wire [DW-1:0] row1;   // pixel one row above the input
    wire [DW-1:0] row2;   // pixel two rows above the input

    line_buffer #(.DW(DW), .DEPTH(W)) lb1 (
        .clk(clk), .rst_n(rst_n), .en(en), .din(pix_in), .dout(row1));
    line_buffer #(.DW(DW), .DEPTH(W)) lb2 (
        .clk(clk), .rst_n(rst_n), .en(en), .din(row1),   .dout(row2));

    reg [CW-1:0] col;
    reg [RW-1:0] row;

    always @(posedge clk) begin
        if (!rst_n) begin
            col <= 0; row <= 0; valid_out <= 1'b0;
            {w00, w01, w02, w10, w11, w12, w20, w21, w22} <= 0;
        end else begin
            valid_out <= 1'b0;
            if (en) begin
                w00 <= w01;  w01 <= w02;  w02 <= row2;
                w10 <= w11;  w11 <= w12;  w12 <= row1;
                w20 <= w21;  w21 <= w22;  w22 <= pix_in;

                valid_out <= (row >= 2) && (col >= 2);

                if (col == W-1) begin
                    col <= 0;
                    row <= (row == H-1) ? 0 : row + 1'b1;
                end else begin
                    col <= col + 1'b1;
                end
            end
        end
    end
endmodule