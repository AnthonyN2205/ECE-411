import rv32i_types::*;

module hazard_detection(
    
    // input rv32i_opcode prev_opcode,
    
    input rv32i_opcode stage_wb_opcode,
    input rv32i_opcode stage_mem_opcode,
	input rv32i_opcode stage_ex_opcode,
    input rv32i_opcode stage_decode_opcode,
    input logic [4:0] stage_mem_rd,
    input logic [4:0] stage_mem_rs2,
    input logic [4:0] stage_ex_rd,
    input logic [4:0] stage_ex_rs1,
    input logic [4:0] stage_ex_rs2,
    input logic [4:0] stage_wb_rd,
    input logic [4:0] stage_decode_rs1,
    input logic [4:0] stage_decode_rs2,
    input logic stage_mem_loadregfile,
    input logic stage_wb_loadregfile,

    output logic forwarded_mem_sel,
    output logic load_stall_hazard,
    output logic [1:0] forwarded_alumux1_sel,
    output logic [1:0] forwarded_alumux2_sel
);

/* lw x4, label
   add x3, x3, x4 
 
      01 -- wb -> mem: 1st lw 2nd st
      10 -- mem -> ex:  rd mem == rs exe, Read after Write hazard,  1 bubble
      11 -- wb -> ex :  rd wb == rs exe, "", 2 bubbles  */
function void set_defaults();
    forwarded_mem_sel = 1'b0;
    forwarded_alumux1_sel = 0;
    forwarded_alumux2_sel = 0;
endfunction

/* stall if loading */
always_comb
begin

    load_stall_hazard = 1'b0;
	 
	if (stage_ex_opcode == op_load) begin
        case(stage_decode_opcode)
            op_br, op_reg: begin
                if (stage_decode_rs1 == stage_ex_rd || stage_decode_rs2 == stage_ex_rd)
                    load_stall_hazard = 1'b1;
            end

            op_imm, op_store, op_jalr: begin
                if (stage_decode_rs1 == stage_ex_rd)
                    load_stall_hazard = 1'b1;
            end

            default: load_stall_hazard = 1'b0;
        endcase
    end
end
    
    
/* ex forwarding */
always_comb 
begin   
            // MEM->EX        
            if (stage_mem_loadregfile && (stage_mem_rd == stage_ex_rs1) && (stage_mem_rd != 5'd0)) begin    
                forwarded_alumux1_sel = 2'b01;  
            end
            // WB->EX
            else if (stage_wb_loadregfile && (stage_wb_rd == stage_ex_rs1) && (stage_wb_rd != 5'd0)) begin
                forwarded_alumux1_sel = 2'b10;
            end

            else
                forwarded_alumux1_sel = 2'b00;
                            
            // MEM->EX 
            if (stage_mem_loadregfile && (stage_mem_rd == stage_ex_rs2) && (stage_mem_rd != 5'd0)) begin
                forwarded_alumux2_sel = 2'b01;
            end
            // WB->EX
            else if (stage_wb_loadregfile && (stage_wb_rd == stage_ex_rs2) && (stage_wb_rd != 5'd0)) begin
                forwarded_alumux2_sel = 2'b10;
            end

            else
                forwarded_alumux2_sel = 2'b00;
end



/* mem forwarding */
always_comb
begin
    forwarded_mem_sel = 1'b0;

    // WB->MEM
    if (stage_wb_loadregfile && (stage_wb_rd != 5'd0) && (stage_wb_rd == stage_mem_rs2))
        forwarded_mem_sel = 1'b1;
    else 
        forwarded_mem_sel = 1'b0;
    
end

endmodule : hazard_detection

 