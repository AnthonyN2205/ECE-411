module arbiter(
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
    output logic write_i
);

logic [1:0] addr_sel;
logic [1:0] rw_sel;
logic mem_wdata_sel;
logic mem_rdata_sel;
logic [1:0] resp_sel;

arbiter_control ARBITER_CONTROL(
    .clk(clk),
    .rst(rst),

    /* Icache signals */
    .icache_read(icache_read_i),
    .icache_write(1'b0),
    /* Dcache signals */
    .dcache_read(dcache_read_i),
    .dcache_write(dcache_write_i),
    /* Memory signals */
    .pmem_resp(resp_o),
    /* Datapath mux selects */
    .addr_sel(addr_sel),
    .rw_sel(rw_sel),
    .mem_wdata_sel(mem_wdata_sel),
    .mem_rdata_sel(mem_rdata_sel),
    .resp_sel(resp_sel)
);

arbiter_datapath ARBITER_DATAPATH(
    .clk(clk),
    .rst(rst),

    .icache_line_i(icache_line_i),
    .icache_read_i(icache_read_i),
    .icache_write_i(icache_write_i),
    .icache_address_i(icache_address_i),
    .icache_line_o(icache_line_o),
    .icache_resp_o(icache_resp_o),

    .dcache_line_i(dcache_line_i),
    .dcache_read_i(dcache_read_i),
    .dcache_write_i(dcache_write_i),
    .dcache_address_i(dcache_address_i),
    .dcache_line_o(dcache_line_o),
    .dcache_resp_o(dcache_resp_o),

    .line_o(line_o),
    .resp_o(resp_o),
    .line_i(line_i),
    .address_i(address_i),
    .read_i(read_i),
    .write_i(write_i),
    
    .addr_sel(addr_sel),
    .rw_sel(rw_sel),
    .mem_wdata_sel(mem_wdata_sel),
    .mem_rdata_sel(mem_rdata_sel),
    .resp_sel(resp_sel)
);

endmodule : arbiter
