import rv32i_types::*;

module cmp
(
    input logic [2:0] cmpop,
    input [31:0] a, b,
    output logic br_en
);

always_comb
begin
    br_en = 0;

    unique case (cmpop)
        beq:     br_en = (a == b);
        bne:     br_en = (a != b);
        blt:     br_en = ($signed(a) < $signed(b));
        bge:     br_en = ($signed(a) >= $signed(b));   
        bltu:    br_en = (a < b);
        bgeu:    br_en = (a >= b);

        default: br_en = 0;
    endcase
end

endmodule : cmp