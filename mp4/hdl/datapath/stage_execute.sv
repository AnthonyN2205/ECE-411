`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)

import rv32i_types::*;

module stage_execute(
    input logic clk,
    input logic rst,

    input rv32i_word rs1_out,
    input rv32i_word rs2_out,

    input rv32i_control_word ctrl,
    /* forwarded data */
    input logic [1:0] forwarded_alumux1_sel,
    input logic [1:0] forwarded_alumux2_sel,
    input rv32i_word alu_out_ex_mem,
    input rv32i_word regfilemux_out_wb,
    
    output logic [31:0] alu_out_ex,
    output rv32i_word forwarded_rs2_out,
    output logic br_en // pcmux_sel (rom)
);

rv32i_word alumux1_out;
rv32i_word alumux2_out;
rv32i_word cmp_mux_out;
rv32i_word forwarded_alumux1_out;
rv32i_word forwarded_alumux2_out;

assign forwarded_rs2_out = forwarded_alumux2_out;

alu ALU(
    .aluop(ctrl.aluop),
    .a(alumux1_out),
    .b(alumux2_out),
    .f(alu_out_ex)
);


cmp CMP(
    .cmpop(ctrl.cmpop),
    .a(forwarded_alumux1_out), 
    .b(cmp_mux_out),
    .br_en(br_en)
); 



always_comb
begin
    alumux1_out = forwarded_alumux1_out;
    alumux2_out = ctrl.i_imm;
    cmp_mux_out = forwarded_alumux2_out;
    forwarded_alumux1_out = rs1_out;
    forwarded_alumux2_out = rs2_out;

    /* forwarded data for alumux1 */
    unique case (forwarded_alumux1_sel)
        /* rs1_out => no hazard */
        2'b00:  forwarded_alumux1_out = rs1_out;
        2'b01:  forwarded_alumux1_out = alu_out_ex_mem;
        2'b10:  forwarded_alumux1_out = regfilemux_out_wb;

        default: forwarded_alumux1_out = rs1_out;
    endcase

    unique case(ctrl.alumux1_sel)
        alumux::rs1_out: alumux1_out = forwarded_alumux1_out;
        alumux::pc_out:  alumux1_out = ctrl.pc; 
        default: `BAD_MUX_SEL;
    endcase

    /* forwarded data for alumux2 */
    unique case (forwarded_alumux2_sel)
        /* rs2_out => no hazard */
        2'b00:  forwarded_alumux2_out = rs2_out;
        2'b01:  forwarded_alumux2_out = alu_out_ex_mem;
        2'b10:  forwarded_alumux2_out = regfilemux_out_wb;

        default: forwarded_alumux2_out = rs2_out;
    endcase

    unique case (ctrl.cmpmux_sel)
        cmpmux::rs2_out: cmp_mux_out = forwarded_alumux2_out;
        cmpmux::i_imm: cmp_mux_out = ctrl.i_imm;

        default: `BAD_MUX_SEL;
    endcase

    unique case (ctrl.alumux2_sel)
        alumux::i_imm: alumux2_out = ctrl.i_imm;
        alumux::u_imm: alumux2_out = ctrl.u_imm;
        alumux::b_imm: alumux2_out = ctrl.b_imm;
        alumux::s_imm: alumux2_out = ctrl.s_imm;
        alumux::j_imm: alumux2_out = ctrl.j_imm;
        alumux::rs2_out: alumux2_out = forwarded_alumux2_out;

        default: `BAD_MUX_SEL;
    endcase

end


endmodule : stage_execute
