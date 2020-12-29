module arbiter_datapath(
    input logic clk,
    input logic rst,

    /* I-cache */
    input logic [255:0] icache_line_i,
    input logic icache_read_i,
    input logic icache_write_i,
    input logic [31:0] icache_address_i,
    
    output logic [255:0] icache_line_o,
    output logic icache_resp_o,

    /* D-cache */
    input logic [255:0] dcache_line_i,
    input logic dcache_read_i,
    input logic dcache_write_i,
    input logic [31:0] dcache_address_i,
    
    output logic [255:0] dcache_line_o,
    output logic dcache_resp_o,

    /* Cacheline */
    input logic [255:0] line_o,
    input logic resp_o,

    output logic [255:0] line_i,
    output logic [31:0] address_i,
    output logic read_i,
    output logic write_i,

    /* From Control */
    input logic [1:0] addr_sel,
    input logic [1:0] rw_sel,
    input logic mem_wdata_sel,
    input logic mem_rdata_sel,
    input logic [1:0] resp_sel
);

logic [31:0] addressmux_out;
logic readmux_out;
logic writemux_out;
logic [255:0] wdatamux_out;

assign address_i = addressmux_out;
assign write_i = writemux_out;
assign read_i = readmux_out;
assign line_i = wdatamux_out;

function void set_defaults();
    readmux_out = '0;
    writemux_out = '0;
    addressmux_out = '0;
    wdatamux_out = '0;
    icache_line_o = '0;
    icache_resp_o = '0;
    dcache_line_o = '0;
    dcache_resp_o = '0;
endfunction 


/* Cache signals
 *
 * output [31:0] pmem_address = address_i
 * input logic [255:0] pmem_rdata = line_o
 * input [31:0] pmem_wdata = line_i
 * output logic pmem_read = read_i
 * output pmem_write = write_i
 * input pmem_resp = resp_o
 */

logic [31:0] icache_prefetch_address;

/* if we're servicing icache and not in prefetch stage, update address for next cacheline */
always_ff @(posedge icache_read_i)
begin
    if (addr_sel != 2'b10)
        icache_prefetch_address = icache_address_i + 32;
end


always_comb
begin: MUXES

    set_defaults();


    /* addr_sel */
    unique case (addr_sel)
        2'b00:  addressmux_out = icache_address_i;
        2'b01:  addressmux_out = dcache_address_i; 
        /* prefetch */
        2'b10:  addressmux_out = icache_prefetch_address;
        default: addressmux_out = '0;
    endcase

    /* read/write */
    unique case (rw_sel)
        2'b00: begin
            readmux_out = icache_read_i;
            writemux_out = icache_write_i;
        end
        2'b01: begin
            readmux_out = dcache_read_i;
            writemux_out = dcache_write_i;
        end

         /* prefetch */
        2'b10: begin
            readmux_out = 1'b1;
            writemux_out = 1'b0;
        end
        
        default: begin
            readmux_out = '0;
            writemux_out = '0;
        end
    endcase

    /* mem_wdata */
    unique case (mem_wdata_sel)
        1'b0: wdatamux_out = '0;
        1'b1: wdatamux_out = dcache_line_i;

        default: wdatamux_out = '0;
    endcase

    /* mem_rdata */
    unique case (mem_rdata_sel)
        1'b0: icache_line_o = line_o;
        1'b1: dcache_line_o = line_o;

        default: begin
            icache_line_o = '0;
            dcache_line_o = '0;
        end
    endcase

    /* resp */
    unique case (resp_sel)
        2'b00: icache_resp_o = resp_o;
        2'b01: dcache_resp_o = resp_o;
        /* prefetch reponse */
        2'b10: icache_resp_o = 1'b0;
        default: begin
            icache_resp_o = 1'b0;
            dcache_resp_o = 1'b0;
        end
    endcase
    
    
end

endmodule : arbiter_datapath
