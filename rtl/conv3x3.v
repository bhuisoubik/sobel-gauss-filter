
module conv3x3 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_in,
    input  wire        mode_in,
    input  wire [7:0]  w00, w01, w02,
    input  wire [7:0]  w10, w11, w12,
    input  wire [7:0]  w20, w21, w22,
    output reg         valid_out,
    output reg         mode_out,
    output reg  [11:0] gsum,
    output reg  signed [10:0] gx,
    output reg  signed [10:0] gy
);
 
    wire signed [8:0] s00 = {1'b0, w00}, s01 = {1'b0, w01}, s02 = {1'b0, w02};
    wire signed [8:0] s10 = {1'b0, w10},                    s12 = {1'b0, w12};
    wire signed [8:0] s20 = {1'b0, w20}, s21 = {1'b0, w21}, s22 = {1'b0, w22};

 
    reg         v1, m1;
    reg  [9:0]  gr0, gr1, gr2;                      
    reg  signed [8:0] dx0, dx1, dx2;                // Gx row differences
    reg  signed [8:0] dy0, dy1, dy2;                // Gy column differences

    always @(posedge clk) begin
        if (!rst_n) begin
            v1 <= 1'b0; m1 <= 1'b0;
            gr0 <= 0; gr1 <= 0; gr2 <= 0;
            dx0 <= 0; dx1 <= 0; dx2 <= 0;
            dy0 <= 0; dy1 <= 0; dy2 <= 0;
        end else begin
            v1  <= valid_in;
            m1  <= mode_in;
            gr0 <= {2'b0, w00} + {1'b0, w01, 1'b0} + {2'b0, w02};
            gr1 <= {2'b0, w10} + {1'b0, w11, 1'b0} + {2'b0, w12};
            gr2 <= {2'b0, w20} + {1'b0, w21, 1'b0} + {2'b0, w22};
            dx0 <= s02 - s00;
            dx1 <= s12 - s10;
            dx2 <= s22 - s20;
            dy0 <= s20 - s00;
            dy1 <= s21 - s01;
            dy2 <= s22 - s02;
        end
    end


    always @(posedge clk) begin
        if (!rst_n) begin
            valid_out <= 1'b0; mode_out <= 1'b0;
            gsum <= 0; gx <= 0; gy <= 0;
        end else begin
            valid_out <= v1;
            mode_out  <= m1;
            gsum <= {2'b0, gr0} + {1'b0, gr1, 1'b0} + {2'b0, gr2}; 
            gx   <= dx0 + (dx1 <<< 1) + dx2;                         
            gy   <= dy0 + (dy1 <<< 1) + dy2;
        end
    end
endmodule