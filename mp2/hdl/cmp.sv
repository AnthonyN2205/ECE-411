import rv32i_types::*;

module cmp
(
    input logic [2:0] cmpop,
    input [31:0] a, b,
    output logic br_en
);

always_comb
begin
    unique case (cmpop)
        beq:     br_en = (a == b);
        bne:     br_en = (a != b);
        blt:     br_en = ($signed(a) < $signed(b));
        bge:     br_en = ($signed(b) >= $signed(b));
        bltu:    br_en = (a < b);
        bgeu:    br_en = (a >= b);

        default:   br_en = (a == b);
    endcase
end

endmodule : cmp