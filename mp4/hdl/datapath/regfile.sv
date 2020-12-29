
module regfile
(
    input clk,
    input rst,
    input load,
    input [31:0] in,
    input [4:0] src_a, src_b, dest,
    output logic [31:0] reg_a, reg_b
);

//logic [31:0] data [32] /* synthesis ramstyle = "logic" */ = '{default:'0};
logic [31:0] data [32];


always_ff @(posedge clk)
begin
    if (rst)
    begin
        for (int i=0; i<32; i=i+1) begin
            data[i] <= '0;
        end
    end
    else if (load && dest)
    begin
        data[dest] <= in;
    end
end

always_comb
begin
    // should fix WB issue where it's writting to dest after 1 cycle but needs data 1 cycle earlier.
    if (src_a)
        if ((src_a == dest) && load)
            reg_a = in;
        else
            reg_a = data[src_a];
    else
        reg_a = 0;

    if (src_b)
        if ((src_b == dest) && load)
            reg_b = in;
        else
            reg_b = data[src_b];
    else
        reg_b = 0;

end

endmodule : regfile
