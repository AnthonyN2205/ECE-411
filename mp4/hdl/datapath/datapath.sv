import rv32i_types::*;

module datapath(
    input logic clk,
    input logic rst,

    /* I/O for caches */
    output logic inst_read,
    output logic [31:0] inst_addr,
    input logic inst_resp,
    input logic [31:0] inst_rdata,

    /* D Cache Ports */
    output logic data_read,
    output logic data_write,
    output logic [3:0] data_mbe,
    output logic [31:0] data_addr,
    output logic [31:0] data_wdata,
    input logic data_resp,
    input logic [31:0] data_rdata
);


/******* FETCH *******/
rv32i_word alu_out_ex;
rv32i_control_word ctrl_decode;
logic br_en_ex;        // from EXE stage
logic load_fetch;
rv32i_word pc_out;

/******* IF_ID *******/
rv32i_word instruction;
rv32i_word fetched_address;
rv32i_word fetched_instruction;

/******* DECODE *******/
rv32i_word regfilemux_out;
rv32i_word rs1_out;
rv32i_word rs2_out;
logic load_regs;

/******* ID_EX *******/
rv32i_control_word ctrl_id_ex;
rv32i_word rs1_reg_out;
rv32i_word rs2_reg_out;

/******* EXECUTE *******/
rv32i_word forwarded_rs2_out;

/******* EX_MEM *******/
logic load_exe;
rv32i_word alu_out_ex_mem;
logic br_en_ex_mem;
rv32i_control_word ctrl_ex_mem;
rv32i_word rs2_out_ex_mem;

/******* MEMORY *******/
rv32i_word dcache_mem_rdata;

/******* MEM_WB *******/
rv32i_control_word ctrl_mem_wb;
rv32i_word alu_out_mem_wb;
logic br_en_mem_wb;

/******* WRITEBACK *******/
rv32i_word mem_rdata_mem_wb;


/******* HAZARD DETECTOR *******/
logic forwarded_mem_sel;
logic load_stall_hazard;
logic [1:0] forwarded_alumux1_sel;
logic [1:0] forwarded_alumux2_sel;



logic pcmux_sel;
rv32i_opcode cur_op;
logic squash;
logic load;
rv32i_word j_imm_bitmask;
assign inst_addr = pc_out;


assign cur_op = ctrl_id_ex.opcode;
/* stall on cache misses */
assign load = ~((inst_read && !inst_resp) || ((data_read || data_write) && (!data_resp)));
assign pcmux_sel = ((br_en_ex && (cur_op == op_br)) || cur_op == op_jal || cur_op == op_jalr);
/* br mispred */
assign squash = (pcmux_sel && load);
assign j_imm_bitmask = (cur_op == op_jalr) ? 32'hFFFFFFFE : '1;





/////////////// Performance Counters ///////////////
int stall_count = 0;
int mispredict_count = 0;
int branch_count = 0;

logic is_branch;
assign is_branch = cur_op == op_br;

/* stall counter */
always_ff @(posedge load_stall_hazard or negedge load)
begin
    stall_count += 1;
end

/* branch misprediction counter */
always_ff @(posedge squash)
begin
    /* squashes on branches only, not jumps */
    if (is_branch)
        mispredict_count += 1;
end

/* branch counter */
always_ff @(posedge is_branch) begin
    branch_count += 1; 
end

/////////////// Performance Counters ///////////////






/* Pipeline Modules */

stage_fetch FETCH(
    .clk(clk),
    .rst(rst),
    .load(load && ~load_stall_hazard),

    /* inputs */
    .alu_out(alu_out_ex),
    .pcmux_sel(pcmux_sel),
    .j_imm_bitmask(j_imm_bitmask),
    
    /* outputs */
    .inst_read(inst_read),
    .pc_out(pc_out)
);

if_id IF_ID(
    .clk(clk),
    .rst(rst || squash),

    /* inputs */
    .load_fetch(load && ~load_stall_hazard),
    .pc_out(pc_out),
    .inst_rdata (inst_rdata),

    /* outputs */
    .fetched_address(fetched_address),
    .fetched_instruction(fetched_instruction)
);

stage_decode DECODE(
    .clk(clk),
    .rst(rst),
    .load(load),

    /* inputs */
    .fetched_address(fetched_address),
    .fetched_instruction(fetched_instruction),
    .regfilemux_out(regfilemux_out),
    .br_en(br_en_ex_mem),
    .ctrl_mem_wb(ctrl_mem_wb),
    
    /* outputs */
    .rs1_out(rs1_out),
    .rs2_out(rs2_out),
    .ctrl_decode(ctrl_decode)
);

id_ex ID_EX(
    .clk(clk),
    .rst(rst || squash || (load_stall_hazard && load)),

    /* inputs */
    .load_regs(load),
    .rs1_in(rs1_out),
    .rs2_in(rs2_out),
    .ctrl(ctrl_decode),

    /* outputs */
    .ctrl_id_ex(ctrl_id_ex),
    .rs1_reg_out(rs1_reg_out),
    .rs2_reg_out(rs2_reg_out)
);

stage_execute EXECUTE(
    .clk(clk),
    .rst(rst),
    
    /* inputs */
    .rs1_out(rs1_reg_out),
    .rs2_out(rs2_reg_out),
    .ctrl(ctrl_id_ex),

    /* Hazard Signals */
    .forwarded_alumux1_sel(forwarded_alumux1_sel),
    .forwarded_alumux2_sel(forwarded_alumux2_sel),
    .alu_out_ex_mem(alu_out_ex_mem),
    .regfilemux_out_wb(regfilemux_out),

    /* outputs */
    .alu_out_ex(alu_out_ex),
    .forwarded_rs2_out(forwarded_rs2_out),
    .br_en(br_en_ex)
);

ex_mem EX_MEM(
    .clk(clk),
    .rst(rst),

    /* inputs */
    .alu_out_ex(alu_out_ex),
    .br_en(br_en_ex),
    .ctrl_id_ex(ctrl_id_ex),
    .load_exe(load),
    .rs2_reg_out(forwarded_rs2_out),
    
    /* outputs */
    .alu_out_ex_mem(alu_out_ex_mem),
    .br_en_ex_mem(br_en_ex_mem),
    .ctrl_ex_mem(ctrl_ex_mem),
    .rs2_out_ex_mem(rs2_out_ex_mem)
);

stage_memory MEMORY(
    .clk(clk),
    .rst(rst),

    /* inputs */
    .alu_out_ex_mem(alu_out_ex_mem),
    .ctrl_ex_mem(ctrl_ex_mem),
    .data_rdata(data_rdata),
    .rs2_out_ex_mem(rs2_out_ex_mem),

    /* Hazard Signals */
    .regfilemux_out_wb(regfilemux_out),
    .forwarded_mem_sel(forwarded_mem_sel),

    /* outputs */
    .data_read(data_read),
    .data_write(data_write),
    .data_mbe(data_mbe),
    .data_addr(data_addr),
    .data_wdata(data_wdata),
    .dcache_mem_rdata(dcache_mem_rdata)
);


mem_wb MEM_WB(
    .clk(clk),
    .rst(rst),

    /* inputs */
    .load_regs(load),
    .alu_out_ex_mem(alu_out_ex_mem),
    .br_en_ex_mem(br_en_ex_mem),
    .ctrl_ex_mem(ctrl_ex_mem),
    .dcache_mem_rdata(dcache_mem_rdata),

    /* outputs */
    .ctrl_mem_wb(ctrl_mem_wb),
    .mem_rdata_mem_wb(mem_rdata_mem_wb),
    .alu_out_mem_wb(alu_out_mem_wb),
    .br_en_mem_wb(br_en_mem_wb)
);

stage_writeback WRITEBACK(
    .clk(clk),
    .rst(rst),

    /* inputs */
    .alu_out(alu_out_mem_wb),
    .br_en(br_en_mem_wb),
    .mem_rdata(mem_rdata_mem_wb),
    .ctrl(ctrl_mem_wb),

    /* outputs */
    .regfilemux_out(regfilemux_out)
);

hazard_detection HAZARD_DETECTION(
    /* inputs */
    .stage_wb_opcode(ctrl_mem_wb.opcode),
    .stage_mem_opcode(ctrl_ex_mem.opcode),
    .stage_ex_opcode(ctrl_id_ex.opcode),
    .stage_decode_opcode(ctrl_decode.opcode),
    .stage_mem_rd(ctrl_ex_mem.rd),
    .stage_mem_rs2(ctrl_ex_mem.rs2),
    .stage_ex_rd(ctrl_id_ex.rd),
    .stage_ex_rs1(ctrl_id_ex.rs1),
    .stage_ex_rs2(ctrl_id_ex.rs2),
    .stage_wb_rd(ctrl_mem_wb.rd),
    .stage_decode_rs1(ctrl_decode.rs1),
    .stage_decode_rs2(ctrl_decode.rs2),
    .stage_mem_loadregfile(ctrl_ex_mem.load_regfile),
    .stage_wb_loadregfile(ctrl_mem_wb.load_regfile),

    /* outputs */
    .forwarded_mem_sel(forwarded_mem_sel),
    .load_stall_hazard(load_stall_hazard),
    .forwarded_alumux1_sel(forwarded_alumux1_sel),
    .forwarded_alumux2_sel(forwarded_alumux2_sel)
);

// hazard_detection1 HAZARD_DETECTION1(
//     .ex_op(ctrl_id_ex.opcode),
//     .decode_op(ctrl_decode.opcode),
//     .decode_rs1(ctrl_decode.rs1),
//     .decode_rs2(ctrl_decode.rs2),
//     .ex_rd(ctrl_id_ex.rd),
//     .ex_rs1(ctrl_id_ex.rs1),
//     .ex_rs2(ctrl_id_ex.rs2),
//     .mem_rd(ctrl_ex_mem.rd),
//     .wb_rd(ctrl_mem_wb.rd),
//     .mem_rs2(ctrl_ex_mem.rs2),
    
//     .load_stall_hazard(load_stall_hazard),
//     .forwarded_alumux1_sel(forwarded_alumux1_sel),
//     .forwarded_alumux2_sel(forwarded_alumux2_sel),
//     .hazard(hazard)
// );

endmodule : datapath
