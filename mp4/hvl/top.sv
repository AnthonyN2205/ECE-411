module mp4_tb;
`timescale 1ns/10ps

/********************* Do not touch for proper compilation *******************/
// Instantiate Interfaces
tb_itf itf();
rvfi_itf rvfi(itf.clk, itf.rst);

// Instantiate Testbench
source_tb tb(
    .magic_mem_itf(itf),
    .mem_itf(itf),
    .sm_itf(itf),
    .tb_itf(itf),
    .rvfi(rvfi)
);

// For local simulation, add signal for Modelsim to display by default
// Note that this signal does nothing and is not used for anything
bit f;


/****************************** End do not touch *****************************/

/************************ Signals necessary for monitor **********************/
// This section not required until CP2

assign rvfi.commit = ((dut.pipeline_datapath.ctrl_mem_wb.opcode != 0) && dut.pipeline_datapath.load); // Set high when a valid instruction is modifying regfile or PC
assign rvfi.halt = ((dut.pipeline_datapath.ctrl_mem_wb.opcode == 7'b1100011) && (dut.pipeline_datapath.ctrl_mem_wb.b_imm == 0));
assign rvfi.inst = dut.pipeline_datapath.fetched_instruction;
assign rvfi.trap = 0;
assign rvfi.rs2_addr = dut.pipeline_datapath.ctrl_mem_wb.rs2;
assign rvfi.rs1_addr = dut.pipeline_datapath.ctrl_mem_wb.rs1;
assign rvfi.rs1_rdata = dut.pipeline_datapath.rs1_out;
assign rvfi.rs2_rdata = dut.pipeline_datapath.rs2_out;
assign rvfi.load_regfile = dut.pipeline_datapath.ctrl_mem_wb.load_regfile;
assign rvfi.rd_addr = dut.pipeline_datapath.ctrl_mem_wb.rd;
assign rvfi.rd_wdata = dut.pipeline_datapath.regfilemux_out;
assign rvfi.pc_rdata = dut.pipeline_datapath.ctrl_mem_wb.pc;
assign rvfi.pc_wdata = dut.pipeline_datapath.ctrl_mem_wb.pc + 4;
assign rvfi.mem_addr = dut.pipeline_datapath.data_addr;
assign rvfi.mem_rmask = dut.pipeline_datapath.data_mbe;
assign rvfi.mem_wmask = dut.pipeline_datapath.data_mbe;
assign rvfi.mem_rdata = dut.pipeline_datapath.data_rdata;
assign rvfi.mem_wdata = dut.pipeline_datapath.alu_out_ex_mem;

/* Temp values ^ */


initial rvfi.order = 0;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO

/*
The following signals need to be set:
Instruction and trap:
    rvfi.inst
    rvfi.trap

Regfile:
    rvfi.rs1_addr
    rvfi.rs2_add
    rvfi.rs1_rdata
    rvfi.rs2_rdata
    rvfi.load_regfile
    rvfi.rd_addr
    rvfi.rd_wdata

PC:
    rvfi.pc_rdata
    rvfi.pc_wdata

Memory:
    rvfi.mem_addr
    rvfi.mem_rmask
    rvfi.mem_wmask
    rvfi.mem_rdata
    rvfi.mem_wdata

Please refer to rvfi_itf.sv for more information.
*/


/**************************** End RVFIMON signals ****************************/

/********************* Assign Shadow Memory Signals Here *********************/
// This section not required until CP2
/*
The following signals need to be set:
icache signals:
    itf.inst_read
    itf.inst_addr
    itf.inst_resp
    itf.inst_rdata

dcache signals:
    itf.data_read
    itf.data_write
    itf.data_mbe
    itf.data_addr
    itf.data_wdata
    itf.data_resp
    itf.data_rdata

Please refer to tb_itf.sv for more information.
*/

assign itf.inst_read = dut.pipeline_datapath.inst_read;
assign itf.inst_addr = dut.pipeline_datapath.inst_addr;
assign itf.inst_resp = dut.pipeline_datapath.inst_resp;
assign itf.inst_rdata = dut.pipeline_datapath.inst_rdata;

assign itf.data_read = dut.pipeline_datapath.data_read;
assign itf.data_write = dut.pipeline_datapath.data_write;
assign itf.data_mbe = dut.pipeline_datapath.data_mbe;
assign itf.data_addr = dut.pipeline_datapath.data_addr;
assign itf.data_wdata = dut.pipeline_datapath.data_wdata;
assign itf.data_resp = dut.pipeline_datapath.data_resp;
assign itf.data_rdata = dut.pipeline_datapath.data_rdata;

/*********************** End Shadow Memory Assignments ***********************/

// Set this to the proper value
assign itf.registers = dut.pipeline_datapath.DECODE.regfile.data;

/*********************** Instantiate your design here ************************/
/*
The following signals need to be connected to your top level:
Clock and reset signals:
    itf.clk
    itf.rst

Burst Memory Ports:
    itf.mem_read
    itf.mem_write
    itf.mem_wdata
    itf.mem_rdata
    itf.mem_addr
    itf.mem_resp

Please refer to tb_itf.sv for more information.
*/

mp4 dut(
    .clk(itf.clk),
    .rst(itf.rst),

    .mem_read(itf.mem_read),
    .mem_write(itf.mem_write),
    .mem_wdata(itf.mem_wdata),
    .mem_rdata(itf.mem_rdata),
    .mem_addr(itf.mem_addr),
    .mem_resp(itf.mem_resp)
);
/***************************** End Instantiation *****************************/

endmodule
