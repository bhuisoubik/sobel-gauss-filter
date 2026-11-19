// Streaming 3x3 image filter. One pixel per clock in, one result per clock out.
// mode = 0: Gaussian blur    mode = 1: Sobel edge magnitude
// Output is valid-only: (W-2) x (H-2) pixels per frame, no border padding.
// Latency: 4 pipeline registers (window, conv stage 1, conv stage 2, output).
// mode must be held constant for the duration of a frame.
module top_filter #(
    parameter W = 64,
    parameter H = 64
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    input  wire       mode,
    input  wire [7:0] pix_in,
    output reg        valid_out,
    output reg  [7:0] pix_out
);
    // Stage 1: window
    wire       win_valid;
    wire [7:0] w00, w01, w02, w10, w11, w12, w20, w21, w22;

    window_3x3 #(.DW(8), .W(W), .H(H)) u_win (
        .clk(clk), .rst_n(rst_n), .en(en), .pix_in(pix_in),
        .valid_out(win_valid),
        .w00(w00), .w01(w01), .w02(w02),
        .w10(w10), .w11(w11), .w12(w12),
        .w20(w20), .w21(w21), .w22(w22));

    // Stages 2-3: convolution datapath
    wire        c_valid, c_mode;
    wire [11:0] c_gsum;
    wire signed [10:0] c_gx, c_gy;

    conv3x3 u_conv (
        .clk(clk), .rst_n(rst_n),
        .valid_in(win_valid), .mode_in(mode),
        .w00(w00), .w01(w01), .w02(w02),
        .w10(w10), .w11(w11), .w12(w12),
        .w20(w20), .w21(w21), .w22(w22),
        .valid_out(c_valid), .mode_out(c_mode),
        .gsum(c_gsum), .gx(c_gx), .gy(c_gy));

    // Stage 4: finish each mode, select, register
    wire [11:0] mag;
    wire [7:0]  sobel_px;
    sobel_mag u_mag (.gx(c_gx), .gy(c_gy), .mag(mag));
    saturate #(.IW(12)) u_sat (.din(mag), .dout(sobel_px));

    wire [11:0] gsum_rnd = c_gsum + 12'd8;      // round-to-nearest before >>4
    wire [7:0]  gauss_px = gsum_rnd[11:4];

    always @(posedge clk) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
            pix_out   <= 8'h00;
        end else begin
            valid_out <= c_valid;
            pix_out   <= c_mode ? sobel_px : gauss_px;
        end
    end
endmodule