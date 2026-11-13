`timescale 1ns/1ps
module tb_window;
    localparam W = 64, H = 64;

    reg clk = 0, rst_n = 0, en = 0;
    reg  [7:0] pix_in = 0;
    wire       valid_out;
    wire [7:0] w00, w01, w02, w10, w11, w12, w20, w21, w22;

    window_3x3 #(.DW(8), .W(W), .H(H)) dut (
        .clk(clk), .rst_n(rst_n), .en(en), .pix_in(pix_in),
        .valid_out(valid_out),
        .w00(w00), .w01(w01), .w02(w02),
        .w10(w10), .w11(w11), .w12(w12),
        .w20(w20), .w21(w21), .w22(w22));

    always #5 clk = ~clk;

    reg [7:0] img [0:W*H-1];
    reg gaps;
    integer k, errors = 0, checked = 0;
    integer r_out = 0, c_out = 0;

    function [7:0] px(input integer r, input integer c);
        px = img[r*W + c];
    endfunction

    // Monitor: compare every valid window against the image array.
    always @(posedge clk) if (valid_out) begin
        if (r_out >= H-2) begin
            errors = errors + 1;
            $display("FAIL: extra valid output at (%0d,%0d)", r_out, c_out);
        end else begin
            if ({w00,w01,w02,w10,w11,w12,w20,w21,w22} !==
                {px(r_out,c_out),   px(r_out,c_out+1),   px(r_out,c_out+2),
                 px(r_out+1,c_out), px(r_out+1,c_out+1), px(r_out+1,c_out+2),
                 px(r_out+2,c_out), px(r_out+2,c_out+1), px(r_out+2,c_out+2)}) begin
                errors = errors + 1;
                if (errors < 10)
                    $display("FAIL: window mismatch at out (%0d,%0d)", r_out, c_out);
            end
            checked = checked + 1;
            if (c_out == W-3) begin c_out = 0; r_out = r_out + 1; end
            else c_out = c_out + 1;
        end
    end

    initial begin
        gaps = $test$plusargs("GAPS");
        $readmemh("data/input.hex", img);
        if (gaps) $dumpfile("sim/tb_window_gaps.vcd"); else $dumpfile("sim/tb_window.vcd");
        $dumpvars(0, tb_window);

        repeat (3) @(negedge clk);
        rst_n = 1;

        for (k = 0; k < W*H; k = k + 1) begin
            if (gaps)
                while (($random & 3) == 0) begin @(negedge clk); en = 0; end
            @(negedge clk);
            en = 1; pix_in = img[k];
        end
        @(negedge clk); en = 0;
        repeat (5) @(negedge clk);

        if (checked != (W-2)*(H-2)) begin
            errors = errors + 1;
            $display("FAIL: expected %0d windows, saw %0d", (W-2)*(H-2), checked);
        end
        if (errors == 0) $display("PASS: tb_window (%0d windows, gaps=%0d)", checked, gaps);
        else             $display("FAIL: tb_window, %0d errors", errors);
        $finish;
    end
endmodule