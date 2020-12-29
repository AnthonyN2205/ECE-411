module arbiter_control(
    input logic clk,
    input logic rst,

    /* I-cache */
    input logic icache_read,
    input logic icache_write,

    /* D-cache */
    input logic dcache_read,
    input logic dcache_write,

    /* Memory */
    input logic pmem_resp,

    /* To Datapath Muxes */
    output logic [1:0] addr_sel,
    output logic [1:0] rw_sel,
    output logic mem_wdata_sel,
    output logic mem_rdata_sel,
    output logic [1:0] resp_sel
);

/* 0 == icache  / 1 == dcache */
function void set_defaults();
    addr_sel = 2'b00;
    rw_sel = 2'b00;
    mem_wdata_sel = 1'b0;
    mem_rdata_sel = 1'b0;
    resp_sel = 2'b00;
endfunction

/* Arbiter states */
enum int unsigned{
    idle = 0,
    icache = 1,
    dcache = 2,
    icache_prefetch = 3
} state, next_state;

/* State Control Signals */
always_comb begin : state_actions

    set_defaults();

    unique case(state)
        idle: begin
            /* wait for a cache miss */
        end

        /* set selects to 0 for icache */
        icache: begin
            addr_sel = 2'b00;
            rw_sel = 2'b00;
            mem_wdata_sel = 1'b0;
            mem_rdata_sel = 1'b0;
            resp_sel = 2'b00;
        end

        /* set selects to 1 for dcache */
        dcache: begin
            addr_sel = 2'b01;
            rw_sel = 2'b01;
            mem_wdata_sel = 1'b1;
            mem_rdata_sel = 1'b1;
            resp_sel = 2'b01;
        end

        icache_prefetch: begin
            addr_sel = 2'b10;
            rw_sel = 2'b10;
            mem_wdata_sel = 1'b0;
            mem_rdata_sel = 1'b0;
            resp_sel = 2'b10;
        end
        

        default: set_defaults();
    endcase
end

/* Next State Logic */
always_comb begin : next_state_logic

    unique case(state)
        idle: begin
            /* Both: Prio goes to I-cache */
            if ((icache_read || icache_write) && (dcache_read || dcache_write))
                next_state = icache;
            /* only I-cache */
            else if ((icache_read || icache_write) && (dcache_read == 0 && dcache_write == 0))
                next_state = icache;
            /* only D-cache */
            else if ((dcache_read || dcache_write) && (icache_read == 0 && icache_write == 0))
                next_state = dcache;
            else
                next_state = idle;
        end

        icache: begin
            /* if dcache has a request, service it */
            if ((dcache_read || dcache_write) && pmem_resp)
                next_state = dcache;
            /* if dcache has no request, done */
            else if (dcache_read == 0 && dcache_write == 0 && pmem_resp)
                next_state = icache_prefetch;
            /* waiting for memory */
            else
                next_state = icache;
        end

        dcache: begin
            /* wait for memory */
            if (pmem_resp && (icache_read == 0 && icache_write == 0))
                next_state = idle;
            else if (pmem_resp && (icache_read || icache_write))
                next_state = icache;
            else
                next_state = dcache;
        end

        icache_prefetch: begin
            if (pmem_resp)
                next_state = idle;
            else
                next_state = icache_prefetch;
        end


       
    endcase

end

/* Assign Next State */
always_ff @(posedge clk) begin : next_state_assignment
    if (rst)
        state <= idle;
    else
        state <= next_state;
end


endmodule : arbiter_control
