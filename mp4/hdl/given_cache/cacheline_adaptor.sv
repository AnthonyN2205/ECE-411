module cacheline_adaptor
(
    input clk,
    input reset_n,

    // Port to LLC (Lowest Level Cache)
    input logic [255:0] line_i,
    output logic [255:0] line_o,
    input logic [31:0] address_i,
    input read_i,
    input write_i,
    output logic resp_o,

    // Port to memory
    input logic [63:0] burst_i,
    output logic [63:0] burst_o,
    output logic [31:0] address_o,
    output logic read_o,
    output logic write_o,
    input resp_i
);

logic [255:0] buffer;

enum int unsigned{
    s_idle = 0,
    s_read0 = 1,
    s_read1 = 2,
    s_read2 = 3,
    s_read3 = 4,
    s_read4 = 5,
    s_write0 = 6,
    s_write1 = 7,
    s_write2 = 8,
    s_write3 = 9,
    s_write4 = 10,
    s_reset = 11
} state, next_state;

/* can't just "assign line_o = buffer" */
always_ff @(posedge clk)
begin
    line_o <= buffer;
end

always_comb
begin : state_actions
    read_o = 1'b0;
    write_o = 1'b0;
    resp_o = 1'b0;
    burst_o = 64'd0;
    buffer = 256'd0;
    address_o = address_i;
    
    case (state)
        s_idle: begin
            
        end

        s_read0: begin
            read_o = 1'b1;
            
            buffer = {line_o[255:64],burst_i};
        end

        s_read1: begin
            read_o = 1'b1;

            buffer = {line_o[255:128], burst_i, line_o[63:0]};
        end

        s_read2: begin
            read_o = 1'b1;

            buffer = {line_o[255:192], burst_i, line_o[127:0]};
        end

        s_read3: begin
            read_o = 1'b1;

            buffer = {burst_i, line_o[191:0]};
        end

        s_read4: begin
            resp_o = 1'b1;
        end

        s_write0: begin
            write_o = 1'b1;

            burst_o = line_i[63:0];
        end

        s_write1: begin
            write_o = 1'b1;

            burst_o = line_i[127:64];
        end

        s_write2: begin
            write_o = 1'b1;

            burst_o = line_i[191:128];
        end

        s_write3: begin
            write_o = 1'b1;

            burst_o = line_i[255:192];
        end

        s_write4: begin
            resp_o = 1'b1;
        end
     
        default: begin
            read_o = 1'b0;
            write_o = 1'b0;
            resp_o = 1'b0;
            burst_o = 64'd0;
            buffer = 256'd0;
        end
    endcase

end

always_comb
begin : next_state_logic
    case (state)
        s_idle: begin
            if (read_i)
                next_state = s_read0;
            else if (write_i)
                next_state = s_write0;
            else
                next_state = s_idle;
        end

        /* read begin */
        s_read0: begin
            /* wait for memory before reading */
            if (resp_i == 1'b1)
                next_state = s_read1;
            else
                next_state = s_read0;
        end

        s_read1: begin
            next_state = s_read2;
        end

        s_read2: begin
            next_state = s_read3;
        end

        s_read3: begin
            next_state = s_read4;
        end

        /* read done */
        s_read4: begin
            if (resp_i == 1'b0)
                next_state = s_idle; 
            else
                next_state = s_read4;
        end

        /* write begin */
        s_write0: begin
            if (resp_i == 1'b1)
                next_state = s_write1;
            else
                next_state = s_write0;
        end

        s_write1: begin
            next_state = s_write2;
        end

        s_write2: begin
            next_state = s_write3;
        end

        s_write3: begin
            next_state = s_write4;
        end

        s_write4: begin
            if (resp_i == 1'b0)
                next_state = s_idle;
            else
                next_state = s_write4;
        end
        

        default: next_state = s_idle;
    endcase
end

always_ff @(posedge clk)
begin : next_state_assignment
    if (reset_n)
        state <= s_idle;

    state <= next_state;
end

endmodule : cacheline_adaptor
