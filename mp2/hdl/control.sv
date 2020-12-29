import rv32i_types::*; /* Import types defined in rv32i_types.sv */

module control
(
    input clk,
    input rst,
    /* memory to control */
    input mem_resp,
    /* datapath to control */
    input rv32i_opcode opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    input logic br_en,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    input rv32i_word mem_address,
    input rv32i_word marmux_out,
    /* control to datapath */
    output pcmux::pcmux_sel_t pcmux_sel,
    output alumux::alumux1_sel_t alumux1_sel,
    output alumux::alumux2_sel_t alumux2_sel,
    output regfilemux::regfilemux_sel_t regfilemux_sel,
    output marmux::marmux_sel_t marmux_sel,
    output cmpmux::cmpmux_sel_t cmpmux_sel,
    output alu_ops aluop,
    output logic load_pc,
    output logic load_ir,
    output logic load_regfile,
    output logic load_mar,
    output logic load_mdr,
    output logic load_data_out,
    /* control to memory */
    output logic mem_read,
    output logic mem_write,
    output logic [3:0] mem_byte_enable,

    /* control to CMP */
    output logic [2:0] cmpop
);

/***************** USED BY RVFIMON --- ONLY MODIFY WHEN TOLD *****************/
logic trap;
logic [4:0] rs1_addr, rs2_addr;
logic [3:0] rmask, wmask;

branch_funct3_t branch_funct3;
store_funct3_t store_funct3;
load_funct3_t load_funct3;
arith_funct3_t arith_funct3;

assign arith_funct3 = arith_funct3_t'(funct3);
assign branch_funct3 = branch_funct3_t'(funct3);
assign load_funct3 = load_funct3_t'(funct3);
assign store_funct3 = store_funct3_t'(funct3);
assign rs1_addr = rs1;
assign rs2_addr = rs2;

always_comb
begin : trap_check
    trap = 0;
    rmask = '0;
    wmask = '0;

    case (opcode)
        op_lui, op_auipc, op_imm, op_reg, op_jal, op_jalr:;

        op_br: begin
            case (branch_funct3)
                beq, bne, blt, bge, bltu, bgeu:;
                default: trap = 1;
            endcase
        end

        op_load: begin
            case (load_funct3)
                lw: rmask = 4'b1111;
                /* which bits to select is based on calculated address */
                lh, lhu: rmask = 4'b0011 << marmux_out[1:0];
                lb, lbu: rmask = 4'b0001 << marmux_out[1:0];
                default: trap = 1;
            endcase
        end

        op_store: begin
            case (store_funct3)
                sw: wmask = 4'b1111;
                sh: wmask = 4'b0011 << marmux_out[1:0]/* Modify for MP1 Final */ ; //  lower 16 bits
                sb: wmask = 4'b0001 << marmux_out[1:0]/* Modify for MP1 Final */ ; //  lower 8 bits
                default: trap = 1;
            endcase
        end

        default: trap = 1;
    endcase
end
/*****************************************************************************/

enum int unsigned {
    /* List of states */
    fetch1          = 0,
    fetch2          = 1,
    fetch3          = 2,
    decode          = 3,
    imm             = 4,
    lui             = 5,
    br              = 6,
    auipc           = 7,
    calc_addr_sw    = 8,
    calc_addr_lw    = 9,
    ld1             = 10,
    ld2             = 11,
    st1             = 12,
    st2             = 13,
    jal             = 14,
    jalr            = 15,
    reg_op          = 16

} state, next_state;

/************************* Function Definitions *******************************/
/**
 *  You do not need to use these functions, but it can be nice to encapsulate
 *  behavior in such a way.  For example, if you use the `loadRegfile`
 *  function, then you only need to ensure that you set the load_regfile bit
 *  to 1'b1 in one place, rather than in many.
 *
 *  SystemVerilog functions must take zero "simulation time" (as opposed to 
 *  tasks).  Thus, they are generally synthesizable, and appropraite
 *  for design code.  Arguments to functions are, by default, input.  But
 *  may be passed as outputs, inouts, or by reference using the `ref` keyword.
**/

/**
 *  Rather than filling up an always_block with a whole bunch of default values,
 *  set the default values for controller output signals in this function,
 *   and then call it at the beginning of your always_comb block.
**/
function void set_defaults();
    load_pc = 1'b0;
    load_ir = 1'b0;
    load_regfile = 1'b0;
    load_mar = 1'b0;
    load_mdr = 1'b0;
    load_data_out = 1'b0;
    pcmux_sel = pcmux::pc_plus4;
    alumux1_sel = alumux::rs1_out;
    alumux2_sel = alumux::i_imm;
    regfilemux_sel = regfilemux::alu_out;
    marmux_sel = marmux::pc_out;
    cmpmux_sel = cmpmux::rs2_out;
    aluop = alu_add;
    mem_read = 1'b0;
    mem_write = 1'b0;
    mem_byte_enable = 4'b1111;
    cmpop = 3'b000;
endfunction

/**
 *  Use the next several functions to set the signals needed to
 *  load various registers
**/
function void loadPC(pcmux::pcmux_sel_t sel);
    load_pc = 1'b1;
    pcmux_sel = sel;
endfunction

function void loadRegfile(regfilemux::regfilemux_sel_t sel);
endfunction

function void loadMAR(marmux::marmux_sel_t sel);
endfunction

function void loadMDR();
endfunction

/**
 * SystemVerilog allows for default argument values in a way similar to
 *   C++.
**/
function void setALU(alumux::alumux1_sel_t sel1,
                               alumux::alumux2_sel_t sel2,
                               logic setop = 1'b0, alu_ops op = alu_add);
    /* Student code here */


    if (setop)
        aluop = op; // else default value
endfunction

function automatic void setCMP(cmpmux::cmpmux_sel_t sel, branch_funct3_t op);
endfunction

/*****************************************************************************/

    /* Remember to deal with rst signal */

always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();
    /* Actions for each state */
    case(state)
        fetch1: begin
            /* mar <- pc */
            load_mar = 1'b1;
        end

        fetch2: begin
            /* mdr <- M[mar] */
            load_mdr = 1'b1;
            mem_read = 1'b1;
        end

        fetch3: begin
            load_ir = 1'b1;
        end

        decode: begin
            /* none */
        end

        imm: begin
            unique case (funct3)
                add: begin
                    load_regfile = 1'b1;
                    load_pc = 1'b1;
                    aluop = alu_add;
                end

                sll: begin
                    load_regfile = 1'b1;
                    load_pc = 1'b1;
                    aluop = alu_sll;
                end

                slt: begin
                    load_regfile = 1'b1;
                    load_pc = 1'b1;
                    aluop = alu_add;
                    cmpop = blt;
                    cmpmux_sel = cmpmux::i_imm;
                    regfilemux_sel = regfilemux::br_en;
                end

                sltu: begin
                    load_regfile = 1'b1;
                    load_pc = 1'b1;
                    aluop = alu_add;
                    cmpop = bltu;
                    cmpmux_sel = cmpmux::i_imm;
                    regfilemux_sel = regfilemux::br_en;
                end

                axor: begin
                    load_regfile = 1'b1;
                    load_pc = 1'b1;
                    aluop = alu_xor;
                    regfilemux_sel = regfilemux::alu_out;
                end

                sr: begin
                    load_regfile = 1'b1;
                    load_pc = 1'b1;

                    if (funct7[5] == 1) begin
                        aluop = alu_sra;
                    end
                    else begin
                        aluop = alu_srl;
                    end
                end

                aor: begin
                    load_regfile = 1'b1;
                    load_pc = 1'b1;
                    aluop = alu_or;
                    regfilemux_sel = regfilemux::alu_out;
                end

                aand: begin
                    load_regfile = 1'b1;
                    load_pc = 1'b1;
                    aluop = alu_and;
                end

                default: begin
                    load_regfile = 1'b1;
                    load_pc = 1'b1;
                    aluop = alu_add;
                end
            endcase
        end

        lui: begin
            load_regfile = 1'b1;
            load_pc = 1'b1;
            regfilemux_sel = regfilemux::u_imm;

        end

        br: begin
            pcmux_sel = pcmux::pcmux_sel_t'(br_en);
            load_pc = 1'b1;
            alumux1_sel = alumux::pc_out;
            alumux2_sel = alumux::b_imm;
            aluop = alu_add;

            unique case (funct3)
                beq:    cmpop = 3'b000;
                bne:    cmpop = 3'b001;
                blt:    cmpop = 3'b100;
                bge:    cmpop = 3'b101;
                bltu:   cmpop = 3'b110;
                bgeu:   cmpop = 3'b111;

                default: cmpop = 3'b000;
            endcase

        end

        reg_op: begin
            load_regfile = 1'b1;
            load_pc = 1'b1;
            alumux2_sel = alumux::rs2_out;
            regfilemux_sel = regfilemux::alu_out;

            unique case(funct3)
                add: begin
                    if (funct7 == 7'b0100000)
                        aluop = alu_sub;
                    else
                        aluop = alu_add;
                end

                sll: begin
                    aluop = alu_sll;
                end

                slt: begin
                    cmpop = blt;
                    cmpmux_sel = cmpmux::rs2_out;
                    regfilemux_sel = regfilemux::br_en;
                end

                sltu: begin
                    cmpop = bltu;
                    cmpmux_sel = cmpmux::rs2_out;
                    regfilemux_sel = regfilemux::br_en;
                end

                axor: begin
                    aluop = alu_xor;
                end

                sr: begin
                    if (funct7 == 7'b0100000)
                        aluop = alu_sra;
                    else
                        aluop = alu_srl;
                end

                default: aluop = alu_ops '(funct3);
            endcase
        end

        auipc: begin
            alumux1_sel = alumux::pc_out;
            alumux2_sel = alumux::u_imm;
            load_regfile = 1'b1;
            load_pc = 1'b1;
            aluop = alu_add;
        end

        calc_addr_sw: begin
            alumux2_sel = alumux::s_imm;
            aluop = alu_add;
            load_mar = 1'b1;
            load_data_out = 1'b1;
            marmux_sel = marmux::alu_out;
        end

        calc_addr_lw: begin
            aluop = alu_add;
            load_mar = 1'b1;
            marmux_sel = marmux::alu_out;
        end

        st1: begin
            mem_write = 1'b1;

            if (funct3 == sb || funct3 == sh) begin
                mem_byte_enable = wmask;
            end

            alumux2_sel = alumux::s_imm;
            aluop = alu_add;
            marmux_sel = marmux::alu_out;
        end

        st2: begin
            load_pc = 1'b1;
        end

        ld1: begin
            load_mdr = 1'b1;
            mem_read = 1'b1;
        end

        ld2: begin
            load_regfile = 1'b1;
            load_pc = 1'b1;
            aluop = alu_add;
            marmux_sel = marmux::alu_out;

            unique case(funct3)
                lb: regfilemux_sel = regfilemux::lb;
                lbu: regfilemux_sel = regfilemux::lbu;
                lh: regfilemux_sel = regfilemux::lh;
                lhu: regfilemux_sel = regfilemux::lhu;
                lw: regfilemux_sel = regfilemux::lw;
                default: regfilemux_sel = regfilemux::alu_out;
            endcase
        end

        jal: begin
            load_regfile = 1'b1;
            load_pc = 1'b1;
            aluop = alu_add;
            alumux1_sel = alumux::pc_out;
            alumux2_sel = alumux::j_imm;
            pcmux_sel = pcmux::alu_mod2;
            regfilemux_sel = regfilemux::pc_plus4;
        end

        jalr: begin
            load_regfile = 1'b1;
            load_pc = 1'b1;
            aluop = alu_add;
            alumux1_sel = alumux::rs1_out;
            alumux2_sel = alumux::i_imm;
            pcmux_sel = pcmux::alu_mod2;
            regfilemux_sel = regfilemux::pc_plus4;
        end

        default: begin
            set_defaults();
        end

    endcase
end

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
    case(state)
        fetch1: begin
            next_state = fetch2;
        end

        fetch2: begin
            if (mem_resp == 0) begin
                next_state = fetch2;
            end
            else begin
                next_state = fetch3;
            end
        end

        fetch3: begin
            next_state = decode;
        end

        decode: begin
            unique case(opcode)
                op_lui:     next_state = lui;
                op_auipc:   next_state = auipc;
                op_jal:     next_state = jal;
                op_jalr:    next_state = jalr;
                op_br:      next_state = br;
                op_load:    next_state = calc_addr_lw;
                op_store:   next_state = calc_addr_sw;
                op_imm:     next_state = imm;
                op_reg:     next_state = reg_op;
                default:    next_state = fetch1;
            endcase
        end

        imm: begin
            next_state = fetch1;
        end

        reg_op: begin
            next_state = fetch1;
        end

        lui: begin
            next_state = fetch1;
        end

        br: begin
            next_state = fetch1;
        end

        auipc: begin
            next_state = fetch1;
        end

        calc_addr_lw: begin
            next_state = ld1;
        end

        calc_addr_sw: begin
            next_state = st1;
        end

        ld1: begin
            if (mem_resp == 0) begin
                next_state = ld1;
            end
            else begin
                next_state = ld2;
            end
        end

        ld2: begin
            next_state = fetch1;
        end

        st1: begin
            if (mem_resp == 0) begin
                next_state = st1;
            end
            else begin
                next_state = st2;
            end
        end

        st2: begin
            next_state = fetch1;
        end

        jal: begin
            next_state = fetch1;
        end

        jalr: begin
            next_state = fetch1;
        end

        default: next_state = fetch1;

    endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
    state <= next_state;
end

endmodule : control
