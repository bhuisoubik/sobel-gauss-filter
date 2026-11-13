`timescale 1ns/1ps
module tb_line_buffer;
    localparam DEPTH = 8;

    reg clk = 0, rst_n = 0, en = 0;
    reg  [7:0] din = 0;
    wire [7:0] dout;

    line_buffer #(.DW(8), .DEPTH(DEPTH)) dut (
        .clk(clk), .rst_n(rst_n), .en(en), .din(din), .dout(dout));

    always #5 clk = ~clk;

    reg [7:0] hist [0:1023];
    integer n = 0, errors = 0, i;

    // Check: each accepted sample must see the one written DEPTH enables ago.
    always @(posedge clk) if (rst_n && en) begin
        if (dout !== ((n >= DEPTH) ? hist[n-DEPTH] : 8'h00)) begin
            errors = errors + 1;
            $display("FAIL: sample %0d dout=%0h expected=%0h", n, dout,
                     (n >= DEPTH) ? hist[n-DEPTH] : 8'h00);
        end
        hist[n] = din;
        n = n + 1;
    end

    initial begin
        $dumpfile("sim/tb_line_buffer.vcd");
        $dumpvars(0, tb_line_buffer);
        repeat (3) @(negedge clk);
        rst_n = 1;
        for (i = 0; i < 500; i = i + 1) begin
            @(negedge clk);
            en  = (($random & 3) != 0);    // ~75% duty: tests stalls too
            din = (i % 255) + 1;
        end
        @(negedge clk); en = 0;
        repeat (3) @(negedge clk);
        if (errors == 0) $display("PASS: tb_line_buffer (%0d samples)", n);
        else             $display("FAIL: tb_line_buffer, %0d errors", errors);
        $finish;
    end
endmodule