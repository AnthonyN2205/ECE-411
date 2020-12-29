import rv32i_types::*;

module control_rom
(
    input rv32i_opcode opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    input logic [31:0] fetched_instruction,
    input logic [31:0] fetched_address,
    input logic br_en,
    output rv32i_control_word ctrl
);

function void set_defaults();
    ctrl.opcode = opcode;
    ctrl.funct3 = funct3;
    ctrl.funct7 = funct7;
    ctrl.aluop = alu_ops'(funct3);
    ctrl.cmpop = branch_funct3_t'(funct3);
    ctrl.regfilemux_sel = regfilemux::alu_out;
    ctrl.alumux1_sel = alumux::rs1_out;
    ctrl.alumux2_sel = alumux::i_imm;
    ctrl.cmpmux_sel = cmpmux::rs2_out;
    ctrl.pcmux_sel = pcmux::pc_plus4;
    ctrl.load_regfile = 1'b0;
    //ctrl.load_pc = 1'b0;
    ctrl.mem_read = 1'b0;
    ctrl.mem_write = 1'b0;
    ctrl.mem_byte_enable = 4'b1111;
    ctrl.rd = fetched_instruction[11:7];
    ctrl.rs1 = fetched_instruction[19:15];
    ctrl.rs2 = fetched_instruction[24:20];
    ctrl.i_imm = {{21{fetched_instruction[31]}}, fetched_instruction[30:20]};
    ctrl.s_imm = {{21{fetched_instruction[31]}}, fetched_instruction[30:25], fetched_instruction[11:7]};
    ctrl.b_imm = {{20{fetched_instruction[31]}}, fetched_instruction[7], fetched_instruction[30:25], fetched_instruction[11:8], 1'b0};
    ctrl.u_imm = {fetched_instruction[31:12], 12'h000};
    ctrl.j_imm = {{12{fetched_instruction[31]}}, fetched_instruction[19:12], fetched_instruction[20], fetched_instruction[30:21], 1'b0};
    ctrl.pc = fetched_address;
endfunction

// default value (alu_out)
function void loadRegfile(regfilemux::regfilemux_sel_t sel);
    ctrl.load_regfile = 1'b1;
    ctrl.regfilemux_sel = sel;
endfunction

// default values (rs1_out, i_imm, alu_add)
function void setALU(alumux::alumux1_sel_t sel1, alumux::alumux2_sel_t sel2, alu_ops op);
    ctrl.alumux1_sel = sel1;
    ctrl.alumux2_sel = sel2;
    ctrl.aluop = op;
endfunction

// default values (rs2_out, funct3)
function void setCMP(cmpmux::cmpmux_sel_t sel, branch_funct3_t op);
    ctrl.cmpmux_sel = sel;
    ctrl.cmpop = op;
endfunction


always_comb
begin
    /* Default assignments */
    set_defaults();

    /* Assign control signals based on opcode */
    case(opcode)
        op_auipc: begin
            setALU(alumux::pc_out, alumux::u_imm, alu_add);
            loadRegfile(regfilemux::alu_out);
        end

        op_lui: begin
            loadRegfile(regfilemux::u_imm);
        end

        op_jal: begin
            setALU(alumux::pc_out, alumux::j_imm, alu_add);
            loadRegfile(regfilemux::pc_plus4);
            //ctrl.pcmux_sel = pcmux::alu_mod2;
        end

        op_jalr: begin
            setALU(alumux::rs1_out, alumux::i_imm, alu_add);
            loadRegfile(regfilemux::pc_plus4);
            //ctrl.pcmux_sel = pcmux::alu_mod2;
        end

        op_br: begin
            setALU(alumux::pc_out, alumux::b_imm, alu_add);
            ctrl.pcmux_sel = pcmux::pcmux_sel_t'(br_en);
        end

        op_load: begin
            ctrl.mem_read = 1'b1;
            setALU(alumux::rs1_out, alumux::i_imm, alu_add);
            
            unique case(funct3)
                lb: loadRegfile(regfilemux::lb);
                lbu: loadRegfile(regfilemux::lbu);
                lh: loadRegfile(regfilemux::lh);
                lhu: loadRegfile(regfilemux::lhu);
                lw: loadRegfile(regfilemux::lw);
                default: loadRegfile(regfilemux::lw);
            endcase
        end

        op_store: begin
            ctrl.mem_write = 1'b1;
            setALU(alumux::rs1_out, alumux::s_imm, alu_add);   
        end

        op_imm: begin
            unique case(funct3)
                add: begin
                    loadRegfile(regfilemux::alu_out);
                    setALU(alumux::rs1_out, alumux::i_imm, alu_add);
                end

                sll: begin
                    loadRegfile(regfilemux::alu_out);
                    setALU(alumux::rs1_out, alumux::i_imm, alu_sll);
                end

                slt: begin
                    loadRegfile(regfilemux::br_en);
                    setCMP(cmpmux::i_imm, blt);
                end

                sltu: begin
                    loadRegfile(regfilemux::br_en);
                    setCMP(cmpmux::i_imm, bltu);
                end

                axor: begin
                    setALU(alumux::rs1_out, alumux::i_imm, alu_xor);
                    loadRegfile(regfilemux::alu_out);
                end

                sr: begin
                    if (funct7[5] == 1) begin
                        setALU(alumux::rs1_out, alumux::i_imm, alu_sra);
                        loadRegfile(regfilemux::alu_out);
					end
                    else begin
                        setALU(alumux::rs1_out, alumux::i_imm, alu_srl);
                        loadRegfile(regfilemux::alu_out);
					end
                end

                aor: begin
                    setALU(alumux::rs1_out, alumux::i_imm, alu_or);
                    loadRegfile(regfilemux::alu_out);
                end

                aand: begin
                    setALU(alumux::rs1_out, alumux::i_imm, alu_and);
                    loadRegfile(regfilemux::alu_out);
                end

                default: begin
                    setALU(alumux::rs1_out, alumux::i_imm, alu_add);
                    loadRegfile(regfilemux::alu_out);
                end
            endcase
        end

        op_reg: begin
            loadRegfile(regfilemux::alu_out);
            
            unique case(funct3)
                add: begin
                    if (funct7[5] == 1)
                        setALU(alumux::rs1_out, alumux::rs2_out, alu_sub);
                    else
                        setALU(alumux::rs1_out, alumux::rs2_out, alu_add);
                end

                sll: begin
                    setALU(alumux::rs1_out, alumux::rs2_out, alu_sll);
                end

                slt: begin
                    setCMP(cmpmux::rs2_out, blt);
                    loadRegfile(regfilemux::br_en);
                end

                sltu: begin
                    setCMP(cmpmux::rs2_out, bltu);
                    loadRegfile(regfilemux::br_en);
                end

                axor: begin
                    setALU(alumux::rs1_out, alumux::rs2_out, alu_xor);
                end

                sr: begin
                    if (funct7[5] == 1)
                        setALU(alumux::rs1_out, alumux::rs2_out, alu_sra);
                    else
                        setALU(alumux::rs1_out, alumux::rs2_out, alu_srl);
                end

                aor: begin
                    setALU(alumux::rs1_out, alumux::rs2_out, alu_or);
                end

                aand: begin
                    setALU(alumux::rs1_out, alumux::rs2_out, alu_and);
                end

                default: begin
                    setALU(alumux::rs1_out, alumux::rs2_out, alu_add);
                    loadRegfile(regfilemux::alu_out);
                end
            endcase
        end

        default: begin
            ctrl = 0;   /* Unknown opcode, set control word to zero */
        end
    endcase
end
endmodule : control_rom

