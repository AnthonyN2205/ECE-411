import rv32i_types::*;

module stage_decode(
    input logic clk,
    input logic rst,
    input logic load,

    input rv32i_word fetched_address,
    input rv32i_word fetched_instruction,
    input rv32i_word regfilemux_out,
    input logic br_en,
    input rv32i_control_word ctrl_mem_wb,
    
    output rv32i_word rs1_out,
    output rv32i_word rs2_out,
    
    /* control signals from ROM */
    output rv32i_control_word ctrl_decode
);

logic [4:0] srcA;
logic [4:0] srcB;
assign srcA = fetched_instruction[19:15];
assign srcB = fetched_instruction[24:20];


regfile regfile(
    .clk(clk),
    .rst(rst),
    .load(ctrl_mem_wb.load_regfile && load),  // load if load_regfile == 1 && cache hit */
    .in(regfilemux_out),
    .src_a(srcA),
    .src_b(srcB),
    .dest(ctrl_mem_wb.rd),
    .reg_a(rs1_out),
    .reg_b(rs2_out)
);

/* refer to MP2: Overview for instruction formats */
control_rom control_rom(
    .opcode(rv32i_opcode'(fetched_instruction[6:0])),
    .funct3(fetched_instruction[14:12]),
    .funct7(fetched_instruction[31:25]),
    .fetched_instruction(fetched_instruction),
    .fetched_address(fetched_address), //ctrl.pc
    .br_en(br_en),
    .ctrl(ctrl_decode) 
);

/*
    014
    0|    000|0001|0100
            10100       pc: 64    rs1_out + i_imm = x60 + x14 = x74
*/

// always_ff @(posedge clk)
// begin
//     load_regs <= 1'b1;
// end


endmodule : stage_decode

