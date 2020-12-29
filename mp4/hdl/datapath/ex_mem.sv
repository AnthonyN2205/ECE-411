import rv32i_types::*;

module ex_mem(
    input logic clk,
    input logic rst,
    
    input rv32i_word alu_out_ex,
    input logic br_en,
    input rv32i_control_word ctrl_id_ex,
    input rv32i_word rs2_reg_out,
    input logic load_exe,

    output rv32i_word alu_out_ex_mem,
    output logic br_en_ex_mem,
    output rv32i_control_word ctrl_ex_mem,
    output rv32i_word rs2_out_ex_mem
);

register ALU_reg(
    .clk(clk),
    .rst(rst),
    .load(load_exe),
    .in(alu_out_ex),
    .out(alu_out_ex_mem)
);

register #(1) BR_reg(
    .clk(clk),
    .rst(rst),
    .load(load_exe),
    .in(br_en),
    .out(br_en_ex_mem)
);

ctrl_register ctrl_reg(
    .clk(clk),
    .rst(rst),
    .load(load_exe),
    .in(ctrl_id_ex),
    .out(ctrl_ex_mem)
);

register RS2_out_reg(
    .clk(clk),
    .rst(rst),
    .load(load_exe),
    .in(rs2_reg_out),
    .out(rs2_out_ex_mem)
);

endmodule : ex_mem
