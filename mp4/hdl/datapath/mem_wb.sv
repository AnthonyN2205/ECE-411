import rv32i_types::*;

module mem_wb(
    input logic clk,
    input logic rst,

    input logic load_regs,
    input rv32i_word alu_out_ex_mem,
    input logic br_en_ex_mem,
    input rv32i_control_word ctrl_ex_mem,
    input rv32i_word dcache_mem_rdata,

    output rv32i_control_word ctrl_mem_wb,
    output rv32i_word mem_rdata_mem_wb,
    output rv32i_word alu_out_mem_wb,
    output logic br_en_mem_wb
);

ctrl_register ctrl_reg(
    .clk(clk),
    .rst(rst),
    .load(load_regs),
    .in(ctrl_ex_mem),
    .out(ctrl_mem_wb)
);

register mem_rdata_reg(
    .clk(clk),
    .rst(rst),
    .load(load_regs),
    .in(dcache_mem_rdata),
    .out(mem_rdata_mem_wb)
);

register alu_reg(
    .clk(clk),
    .rst(rst),
    .load(load_regs),
    .in (alu_out_ex_mem),
    .out(alu_out_mem_wb)
);

register #(1) br_en_reg(
    .clk(clk),
    .rst(rst),
    .load(load_regs),
    .in(br_en_ex_mem),
    .out(br_en_mem_wb)
);

endmodule : mem_wb
