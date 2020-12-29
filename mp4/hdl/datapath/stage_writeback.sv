`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)

import rv32i_types::*;

module stage_writeback(
    input logic clk,
    input logic rst,

    input logic [31:0] alu_out,
    input logic br_en,
    //input logic [31:0] u_imm,
    input logic [31:0] mem_rdata,
    input rv32i_control_word ctrl,

    output rv32i_word regfilemux_out
);

always_comb
begin
    regfilemux_out = 0;
    
    unique case (ctrl.regfilemux_sel)
        regfilemux::alu_out: regfilemux_out = alu_out;
        regfilemux::br_en: regfilemux_out = {31'b0, br_en};
        regfilemux::u_imm: regfilemux_out = ctrl.u_imm;
        regfilemux::lw: regfilemux_out = mem_rdata;
        regfilemux::lb: regfilemux_out = mem_rdata;
        regfilemux::lh: regfilemux_out = mem_rdata;
        regfilemux::pc_plus4: regfilemux_out = ctrl.pc + 32'd4;
        
        default: `BAD_MUX_SEL;
    endcase
end

endmodule : stage_writeback
