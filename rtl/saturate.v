// Clamp an unsigned value to 0..255.
module saturate #(
    parameter IW = 12
)(
    input  wire [IW-1:0] din,
    output wire [7:0]    dout
);
    assign dout = (|din[IW-1:8]) ? 8'hFF : din[7:0];
endmodule