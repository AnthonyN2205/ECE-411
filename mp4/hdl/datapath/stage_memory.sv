import rv32i_types::*;

module stage_memory(
    input logic clk,
    input logic rst,

    input rv32i_word alu_out_ex_mem,
    input rv32i_control_word ctrl_ex_mem,
    input rv32i_word data_rdata,
    input rv32i_word rs2_out_ex_mem,

    /* hazard signals */
    input rv32i_word regfilemux_out_wb,
    input logic forwarded_mem_sel,

    output logic data_read,
    output logic data_write,
    output logic [3:0] data_mbe,
    output logic [31:0] data_addr,
    output logic [31:0] data_wdata,
    output rv32i_word dcache_mem_rdata
);

/* 
    hazard == 01 ... FORWARDING LINE: regfilemux_out (stage_wb) ---> dcache_wdata (stage_mem)
              
*/

rv32i_word forwarded_datamux_out;


/* mem_byte enable logic for store */
always_comb
begin
    
    data_mbe = 4'b0000;
    dcache_mem_rdata = 0;
    forwarded_datamux_out = '0;

    unique case (forwarded_mem_sel)
            1'b0: forwarded_datamux_out = rs2_out_ex_mem;
            1'b1: forwarded_datamux_out = regfilemux_out_wb;
            
            default: forwarded_datamux_out = rs2_out_ex_mem;
    endcase

    
    if (ctrl_ex_mem.opcode == op_load) begin
        unique case (load_funct3_t'(ctrl_ex_mem.funct3))
            lw: dcache_mem_rdata = data_rdata;

            lh: begin
                unique case (alu_out_ex_mem[1:0])
                    /* can be XX00, 0XX0, 00XX */
                    2'b00: dcache_mem_rdata = {{16{data_rdata[7]}}, data_rdata[15:0]};
                    2'b01: dcache_mem_rdata = {{16{data_rdata[23]}}, data_rdata[23:8]};
                    2'b10: dcache_mem_rdata = {{16{data_rdata[31]}}, data_rdata[31:16]};
                    2'b11: dcache_mem_rdata = 32'h0;

                    default: dcache_mem_rdata = {{16{data_rdata[15]}}, data_rdata[15:0]};
                endcase
            end

            lhu: begin
                unique case (alu_out_ex_mem[1:0])
                    2'b00: dcache_mem_rdata = {16'h0, data_rdata[15:0]};
                    2'b01: dcache_mem_rdata = {16'h0, data_rdata[23:8]};
                    2'b10: dcache_mem_rdata = {16'h0, data_rdata[31:16]};
                    2'b11: dcache_mem_rdata = 32'h0;

                    default: dcache_mem_rdata = {16'h0, data_rdata[15:0]};
                endcase
            end

            lb: begin
                unique case (alu_out_ex_mem[1:0])
                    /* sign extend MSB */
                    2'b00: dcache_mem_rdata = {{24{data_rdata[7]}}, data_rdata[7:0]};
                    2'b01: dcache_mem_rdata = {{24{data_rdata[15]}}, data_rdata[15:8]};
                    2'b10: dcache_mem_rdata = {{24{data_rdata[23]}}, data_rdata[23:16]};
                    2'b11: dcache_mem_rdata = {{24{data_rdata[31]}}, data_rdata[31:24]};

                    default: dcache_mem_rdata = {24'd0, data_rdata[7:0]};
                endcase
            end

            lbu: begin
                unique case (alu_out_ex_mem[1:0])
                    2'b00: dcache_mem_rdata = {24'h0, data_rdata[7:0]};
                    2'b01: dcache_mem_rdata = {24'h0, data_rdata[15:8]};
                    2'b10: dcache_mem_rdata = {24'h0, data_rdata[23:16]};
                    2'b11: dcache_mem_rdata = {24'h0, data_rdata[31:24]};

                    default: dcache_mem_rdata = {24'h0, data_rdata[7:0]};
                endcase
            end

            default: dcache_mem_rdata = data_rdata;
        endcase 
    end


    if (ctrl_ex_mem.opcode == op_store) begin
        unique case (store_funct3_t'(ctrl_ex_mem.funct3))
            sw: data_mbe = 4'b1111;
            sh: data_mbe = 4'b0011 << (alu_out_ex_mem[1:0] * 8);
            sb: data_mbe = 4'b0001 << (alu_out_ex_mem[1:0] * 8);
            default: data_mbe = 4'b1111;
        endcase
    end     
end

assign data_read = ctrl_ex_mem.mem_read;
assign data_write = ctrl_ex_mem.mem_write;
assign data_addr = (ctrl_ex_mem.mem_read || ctrl_ex_mem.mem_write) ? {alu_out_ex_mem[31:2], 2'b00} : 0;
assign data_wdata = forwarded_datamux_out;


endmodule : stage_memory
