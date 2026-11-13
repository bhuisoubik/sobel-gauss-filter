// One-row delay line. When en is high, dout shows the sample that was
// written DEPTH enables ago (0 before the buffer has filled), while din
// is stored in its place. dout is a combinational read so it lines up
// with the current input pixel; this maps to distributed RAM, not
// registered-read BRAM (note this in the README).
module line_buffer #(
    parameter DW    = 8,
    parameter DEPTH = 64
)(
    input  wire          clk,
    input  wire          rst_n,
    input  wire          en,
    input  wire [DW-1:0] din,
    output wire [DW-1:0] dout
);
    localparam AW = $clog2(DEPTH);

    reg [DW-1:0] mem [0:DEPTH-1];
    reg [AW-1:0] ptr;
    integer i;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1) mem[i] = {DW{1'b0}};
    end

    assign dout = mem[ptr];

    always @(posedge clk) begin
        if (!rst_n) begin
            ptr <= {AW{1'b0}};
        end else if (en) begin
            mem[ptr] <= din;
            ptr      <= (ptr == DEPTH-1) ? {AW{1'b0}} : ptr + 1'b1;
        end
    end
endmodule