import rv32i_types::*;

module if_id(
    input logic clk,
    input logic rst,

    input logic load_fetch,
    input rv32i_word pc_out,
    input rv32i_word inst_rdata,

    output rv32i_word fetched_address,
    output rv32i_word fetched_instruction
);

register addr_reg(
    .clk(clk),
    .rst(rst),
    .load(load_fetch),
    .in(pc_out),
    .out(fetched_address)
);

register instr_reg(
    .clk(clk),
    .rst(rst),
    .load(load_fetch),
    .in(inst_rdata),
    .out(fetched_instruction)
);

endmodule : if_id
