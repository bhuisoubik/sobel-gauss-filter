module sobel_mag (
    input  wire signed [10:0] gx,
    input  wire signed [10:0] gy,
    output wire        [11:0] mag
);
    wire [10:0] ax = gx[10] ? (~gx + 11'd1) : gx;
    wire [10:0] ay = gy[10] ? (~gy + 11'd1) : gy;
    assign mag = {1'b0, ax} + {1'b0, ay};
endmodule