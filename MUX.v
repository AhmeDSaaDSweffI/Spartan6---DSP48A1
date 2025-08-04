module reg_mux(rst, clk, ce, sel, in, out_mux);
    parameter reg_size = 18;
    parameter RST_TYPE = "SYNC";
    input rst, clk, ce, sel;
    input [reg_size-1:0] in;
    output wire [reg_size-1:0] out_mux;
    reg [reg_size-1:0] out_ff;
 
    generate
        if (RST_TYPE == "SYNC") begin
            always @(posedge clk) begin
                if (rst)
                    out_ff <= {reg_size{1'b0}};
                else if (ce)
                    out_ff <= in;
            end
        end else begin
            always @(posedge clk or posedge rst) begin
                if (rst)
                    out_ff <= {reg_size{1'b0}};
                else if (ce)
                    out_ff <= in;
            end
        end
    endgenerate
 
    assign out_mux = (sel) ? out_ff : in;
endmodule