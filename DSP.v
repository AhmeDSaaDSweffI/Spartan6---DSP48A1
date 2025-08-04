module firstDSP(A, B, C, D, CARRYIN, clk, opmode, BCIN,
    CEA, CEB, CEC, CECARRYIN, CED, CEM, CEOPMODE, CEP,
    RSTA, RSTB, RSTC, RSTCARRYIN, RSTD, RSTM, RSTOPMODE, RSTP,
    BCOUT, PCIN, PCOUT, M, P, CARRYOUT, CARRYOUTF);
 
    parameter A0REG = 0;
    parameter A1REG = 1;
    parameter B0REG = 0;
    parameter B1REG = 1;
    parameter CREG = 1;
    parameter DREG = 1;
    parameter MREG = 1;
    parameter PREG = 1;
    parameter CARRYINREG = 1;
    parameter CARRYOUTREG = 1;
    parameter OPMODEREG = 1;
    parameter CARRYINSEL = "OPMODE5";
    parameter B_INPUT = "DIRECT";
    parameter RSTTYPE = "SYNC";
 
    input clk, CEA, CEB, CEC, CECARRYIN, CED, CEM, CEOPMODE, CEP;
    input RSTA, RSTB, RSTC, RSTCARRYIN, RSTD, RSTM, RSTOPMODE, RSTP, CARRYIN;
    input [7:0] opmode;
    input [17:0] A, B, D, BCIN;
    input [47:0] C, PCIN;
    output CARRYOUT, CARRYOUTF;
    output [17:0] BCOUT;
    output [35:0] M;
    output [47:0] P, PCOUT;
 
    wire CYI, CIN, carryout_postsum;
    wire [7:0] opmode_mux;
    wire [17:0] A0, A1, B0, B1, D_mux, B_mux, PRE_SUM, B0_mux;
    wire [35:0] prod;
    wire [47:0] C_mux, conc_signal, post_sum;
    reg [47:0] X_mux, Z_mux;
 
    assign CYI = (CARRYINSEL == "OPMODE5") ? opmode_mux[5] : (CARRYINSEL == "CARRYIN") ? CARRYIN : 0;
    assign B_mux = (B_INPUT == "DIRECT") ? B : (B_INPUT == "CASCADE") ? BCIN : 0;
    assign PRE_SUM = (opmode_mux[6]) ? D_mux- B0 : D_mux + B0;
    assign B0_mux = (opmode_mux[4]) ? PRE_SUM : B0;
    assign conc_signal = {D_mux[11:0], A1, B1};
    assign prod = A1 * B1;
    assign BCOUT = B1;
    assign {carryout_postsum, post_sum} = (opmode_mux[7]) ? (Z_mux- (X_mux + CIN)) : (Z_mux + X_mux + CIN);
    assign CARRYOUTF = CARRYOUT;
    assign PCOUT = P;
 
    reg_mux #(.reg_size(18), .RST_TYPE(RSTTYPE)) A0_REG (RSTA, clk, CEA, A0REG, A, A0);
    reg_mux #(.reg_size(18), .RST_TYPE(RSTTYPE)) A1_REG (RSTA, clk, CEA, A1REG, A0, A1);
    reg_mux #(.reg_size(18), .RST_TYPE(RSTTYPE)) B0_REG (RSTB, clk, CEB, A0REG, B_mux,B0);
    reg_mux #(.reg_size(18), .RST_TYPE(RSTTYPE)) B1_REG (RSTB, clk, CEB, A1REG, B0_mux,B1);
    reg_mux #(.reg_size(18), .RST_TYPE(RSTTYPE)) D_REG (RSTD, clk, CED, DREG, D, D_mux);
    reg_mux #(.reg_size(48), .RST_TYPE(RSTTYPE)) C_REG (RSTC, clk, CEC, CREG, C, C_mux);
    reg_mux #(.reg_size(8), .RST_TYPE(RSTTYPE)) OPMODE_REG (RSTOPMODE, clk, CEOPMODE,OPMODEREG, opmode, opmode_mux);
    reg_mux #(.reg_size(36), .RST_TYPE(RSTTYPE)) M_REG (RSTM, clk, CEM, MREG, prod, M);
    reg_mux #(.reg_size(1), .RST_TYPE(RSTTYPE)) CARRYIN_REG (RSTCARRYIN, clk, CECARRYIN,CARRYINREG, CYI, CIN);
    reg_mux #(.reg_size(1), .RST_TYPE(RSTTYPE)) CARRYOUT_REG (RSTCARRYOUT, clk,CECARRYOUT, CARRYOUTREG, carryout_postsum, CARRYOUT);
    reg_mux #(.reg_size(48), .RST_TYPE(RSTTYPE)) P_REG (RSTP, clk, CEP, PREG, post_sum, P);
    
    always @(*) begin
        case ({opmode_mux[1], opmode_mux[0]})
            2'b00: X_mux = 0;
            2'b01: X_mux = M;
            2'b10: X_mux = PCOUT;
            2'b11: X_mux = conc_signal;
        endcase
    end
 
    always @(*) begin
        case ({opmode_mux[3], opmode_mux[2]})
            2'b00: Z_mux = 0;
            2'b01: Z_mux = PCIN;
            2'b10: Z_mux = P;
            2'b11: Z_mux = C_mux;
        endcase
  end
endmodule