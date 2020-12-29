/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */

module cache_control (
    input clk,
    input rst,

    /* Cache <--> CPU */
    input logic mem_read,
    input logic mem_write,

    output logic mem_resp,

    /* Cache <--> Cacheline */
    input logic pmem_resp,

    output logic pmem_read,
    output logic pmem_write,

    /* Cache <--> Datapath */
    input logic hit0,
    input logic valid0,
    input logic dirty0,
    input logic hit1,
    input logic valid1,
    input logic dirty1,
    input logic LRU,

    output logic load_tag0,
    output logic load_data0,
    output logic load_valid0,
    output logic load_dirty0,
    output logic load_tag1,
    output logic load_data1,
    output logic load_valid1,
    output logic load_dirty1,
    output logic load_LRU,
    output logic dirty0_o,
    output logic dirty1_o,
    output logic valid0_o,
    output logic valid1_o,
    output logic lru_data_i,

    /* mux select */
    output logic tag_mux_sel,
    output logic data_mux_sel,
    output logic [1:0] rdata_mux_sel,
    output logic [1:0] pmem_mux_sel
);

enum int unsigned {
    /* list of states */
    idle = 0,
    read = 1,
    write = 2,
    write_back = 3,
    memory = 4
} state, next_state;

function void set_defaults();
    load_tag0 = 1'b0;
    load_data0 = 1'b0;
    load_valid0 = 1'b0;
    load_dirty0 = 1'b0;
    load_tag1 = 1'b0;
    load_data1 = 1'b0;
    load_valid1 = 1'b0;
    load_dirty1 = 1'b0;
    load_LRU = 1'b0;
    mem_resp = 1'b0;
    pmem_read = 1'b0;
    pmem_write = 1'b0;
    dirty0_o = 1'b0;
    dirty1_o = 1'b0;
    valid0_o = 1'b0;
    valid1_o = 1'b0; 
    pmem_mux_sel = 2'b00;
    lru_data_i = 1'b0;
    tag_mux_sel = 1'b0;
    data_mux_sel = 1'b0;
    rdata_mux_sel = 2'b11;
    pmem_mux_sel = 2'b00;
endfunction

always_comb
begin : state_actions
    set_defaults();

    case (state) 
        idle: begin
            /* wait for mem_read/mem_write */
            if (mem_read == 1'b1) begin
                // hit 0
                if (hit0) begin
                    load_LRU = 1'b1;
                    mem_resp = 1'b1;
                    lru_data_i = 1'b1; // flip LRU bit
                    rdata_mux_sel = 2'b00;
                end

                // hit 1
                else if (hit1) begin
                    load_LRU = 1'b1;
                    mem_resp = 1'b1;
                    lru_data_i = 1'b0; // flip LRU bit
                    rdata_mux_sel = 2'b01;
                end
                // miss
            end
            else if (mem_write == 1'b1) begin
                // hit 0
                if (hit0) begin
                    mem_resp = 1'b1;
                    load_LRU = 1'b1;
                    lru_data_i = 1'b1; // flip LRU bit
                    load_dirty0 = 1'b1;
                    dirty0_o = 1'b1;
                    load_data0 = 1'b1;
                    /* mux sel */
                    pmem_mux_sel = 1'b0; 
                    data_mux_sel = 1'b0;
                    rdata_mux_sel = 2'b00;
                end

                // hit 1
                else if (hit1) begin
                    mem_resp = 1'b1;
                    load_LRU = 1'b1;
                    lru_data_i = 1'b0; // flip LRU bit
                    load_dirty1 = 1'b1;
                    dirty1_o = 1'b1;
                    load_data1 = 1'b1;
                    /* mux sel */
                    pmem_mux_sel = 1'b1; 
                    data_mux_sel = 1'b1;
                    rdata_mux_sel = 2'b01;
                end
                // miss
            end
        end

        write_back: begin
            pmem_write = 1'b1;

            // way 0, data dirty
            if (LRU == 1'b0) begin
                load_dirty0 = 1'b1;
                dirty0_o = 1'b1;
                pmem_mux_sel = 2'b01;
            end
            else if (LRU == 1'b1) begin
                load_dirty1 = 1'b1;
                dirty1_o = 1'b1;
                pmem_mux_sel = 2'b10;
            end
        end


        memory: begin
            /* send read request to memory */
            pmem_read = 1'b1;

            // way 0
            if (LRU == 1'b0) begin
                load_tag0 = 1'b1;
                load_valid0 = 1'b1;
                valid0_o = 1'b1;
                load_data0 = 1'b1;
            end
            // way 1
            else if (LRU == 1'b1) begin
                load_tag1 = 1'b1;
                load_valid1 = 1'b1;
                valid1_o = 1'b1;
                load_data1 = 1'b1;
            end
        end

    endcase
end

always_comb
begin : next_state_logic
    case (state)
        idle: begin
            // hit, send data 
            if (hit0 == 1'b1 || hit1 == 1'b1 || (mem_read == 1'b0 && mem_write == 1'b0))
                next_state = idle;

            // if miss
            else if (valid0 == 1'b1 && valid1 == 1'b1) begin
                // if miss, check if dirty way
                if (LRU == 1'b0 && dirty0 == 1'b1 || (LRU == 1'b1 && dirty1 == 1'b1))
                    next_state = write_back;
                else
                    next_state = memory;
            end

            else
                // not valid ways and a miss, (cold start)
                next_state = memory;
        end

        write_back: begin
            // wait for memory to finish task
            if (pmem_resp == 1'b1)
                next_state = memory;
            else
                next_state = write_back;
        end

        memory: begin
            // wait for memory to finish task
            if (pmem_resp == 1'b1)
                next_state = idle;
            else
                next_state = memory; 
        end

        default: next_state = idle;
    endcase
end

always_ff @(posedge clk)
begin : next_state_assignment 
    if (rst)
        state <= idle;

    state <= next_state;
end

endmodule : cache_control
