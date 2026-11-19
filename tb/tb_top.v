`timescale 1ns/1ps
 
module tb_top;
    localparam W = 64, H = 64, NOUT = (W-2)*(H-2);

    reg clk = 0, rst_n = 0, en = 0, mode = 0;
    reg  [7:0] pix_in = 0;
    wire       valid_out;
    wire [7:0] pix_out;

    top_filter #(.W(W), .H(H)) dut (
        .clk(clk), .rst_n(rst_n), .en(en), .mode(mode),
        .pix_in(pix_in), .valid_out(valid_out), .pix_out(pix_out));

    always #5 clk = ~clk;

    reg [7:0] img    [0:W*H-1];
    reg [7:0] golden [0:NOUT-1];
    integer k, n, errors, mode_i, fd;
    reg gaps;
    reg [8*64-1:0] outname, vcdname;


    always @(posedge clk) if (valid_out) begin
        if (n < NOUT) begin
            if (pix_out !== golden[n]) begin
                errors = errors + 1;
                if (errors < 10)
                    $display("FAIL: out %0d (r%0d,c%0d) got %0d expected %0d",
                             n, n/(W-2), n%(W-2), pix_out, golden[n]);
            end
            $fwrite(fd, "%02x\n", pix_out);
        end
        n = n + 1;
    end

    initial begin
        n = 0; errors = 0;
        gaps = $test$plusargs("GAPS");
        if ($value$plusargs("MODE=%d", mode_i)) mode = mode_i[0];
        if (!$value$plusargs("OUT=%s", outname)) outname = "sim/out.hex";
        if (!$value$plusargs("VCD=%s", vcdname)) vcdname = "sim/tb_top.vcd";

        $readmemh("data/input.hex", img);
        if (mode) $readmemh("data/expected_sobel.hex", golden);
        else      $readmemh("data/expected_gauss.hex", golden);

        fd = $fopen(outname, "w");
        $dumpfile(vcdname);
        $dumpvars(0, tb_top);

        repeat (3) @(negedge clk);
        rst_n = 1;

        for (k = 0; k < W*H; k = k + 1) begin
            if (gaps)
                while (($random & 3) == 0) begin @(negedge clk); en = 0; end
            @(negedge clk);
            en = 1; pix_in = img[k];
        end
        @(negedge clk); en = 0;
        repeat (10) @(negedge clk);          
        $fclose(fd);

        if (n != NOUT) begin
            errors = errors + 1;
            $display("FAIL: expected %0d outputs, saw %0d", NOUT, n);
        end
        if (errors == 0)
            $display("PASS: tb_top mode=%0d gaps=%0d (%0d pixels)", mode, gaps, n);
        else
            $display("FAIL: tb_top mode=%0d gaps=%0d, %0d errors", mode, gaps, errors);
        $finish;
    end
endmodule