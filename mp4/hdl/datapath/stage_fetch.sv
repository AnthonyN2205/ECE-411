`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)

import rv32i_types::*;

module stage_fetch(
    input logic clk,
    input logic rst,
    input logic load,

    input rv32i_word alu_out,
    input logic pcmux_sel,
    input logic [31:0] j_imm_bitmask,
    
    output logic inst_read,
    output rv32i_word pc_out // fetch->if_id->exec
);

rv32i_word pcmux_out;

/* PC */
pc_register PC(
    .clk(clk),
    .rst(rst),
    .load(load),
    .in(pcmux_out),
    .out(pc_out)
);

/* PC mux */
always_comb
begin
	pcmux_out = 32'd0;

    if (rst)
        inst_read = 1'b0;
    else
        inst_read = 1'b1;
	 
    unique case (pcmux_sel)
        1'b0: pcmux_out = pc_out + 4;
        1'b1: pcmux_out = alu_out & j_imm_bitmask;
        //pcmux::alu_mod2: pcmux_out = {alu_out[31:2], 2'd0};   

        default: pcmux_out = pc_out + 4;
    endcase
end



endmodule : stage_fetch
