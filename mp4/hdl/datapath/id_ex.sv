import rv32i_types::*;

module id_ex(
    input logic clk,
    input logic rst,

    input logic load_regs,
    input rv32i_word rs1_in, // rs1_out (decode stage)
    input rv32i_word rs2_in, // rs2_out (decode stage)
    input rv32i_control_word ctrl, 

    output rv32i_control_word ctrl_id_ex,
    output rv32i_word rs1_reg_out,
    output rv32i_word rs2_reg_out
);


ctrl_register ctrl_reg(
    .clk(clk),
    .rst(rst),
    .load(load_regs),
    .in(ctrl),
    .out(ctrl_id_ex)
);


register rs1_reg(
    .clk(clk),
    .rst(rst),
    .load(load_regs),
    .in(rs1_in),
    .out(rs1_reg_out)
);

register rs2_reg(
    .clk(clk),
    .rst(rst),
    .load(load_regs),
    .in(rs2_in),
    .out(rs2_reg_out)
);

endmodule : id_ex
