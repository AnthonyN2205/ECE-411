/* MODIFY. Your cache design. It contains the cache
controller, cache datapath, and bus adapter. */

module cache #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
    input clk,
    input rst,

    /* CPU <--> Cache */
    input [31:0] mem_address,
    output [31:0] mem_rdata,
    input [31:0] mem_wdata,
    input logic mem_read,
    input logic mem_write,
    input logic [3:0] mem_byte_enable,
    output mem_resp,

    /* Cache <--> Memory */
    output [31:0] pmem_address,         // address_i
    input logic [255:0] pmem_rdata,     // line_o
    output logic [255:0] pmem_wdata,    // line_i
    output logic pmem_read,             // read_i
    output logic pmem_write,            // write_i
    input logic pmem_resp              // resp_o
);
/* datapath --> bus */
logic [255:0] mem_rdata256;
logic [255:0] mem_wdata256;
logic [31:0] mem_byte_enable256;

/* control --> datapath */
logic load_tag0;
logic load_data0;
logic load_valid0;
logic load_dirty0;
logic load_tag1;
logic load_data1;
logic load_valid1;
logic load_dirty1;
logic load_LRU;
logic lru_data_i;

logic tag_mux_sel;
logic data_mux_sel;
logic [1:0] rdata_mux_sel;
logic [1:0] pmem_mux_sel;

/* datapath --> control */
logic hit0;
logic hit1;
logic valid0;
logic valid1;
logic dirty0;
logic dirty1;
logic LRU;

logic dirty0_o;
logic dirty1_o;
logic valid0_o;
logic valid1_o;



cache_control control
(
    .clk(clk),
    .rst(rst),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_resp(mem_resp),
    .pmem_resp(pmem_resp),
    .pmem_read(pmem_read),
    .pmem_write(pmem_write),
    .load_tag0(load_tag0),
    .load_data0(load_data0),
    .load_valid0(load_valid0),
    .load_dirty0(load_dirty0),
    .load_tag1(load_tag1),
    .load_data1(load_data1),
    .load_valid1(load_valid1),
    .load_dirty1(load_dirty1),
    .load_LRU(load_LRU),
    .lru_data_i(lru_data_i),
    .hit0(hit0),
    .hit1(hit1),
    .valid0(valid0),
    .valid1(valid1),
    .dirty0(dirty0),
    .dirty1(dirty1),
    .dirty0_o(dirty0_o),
    .dirty1_o(dirty1_o),
    .valid0_o(valid0_o),
    .valid1_o(valid1_o),
    .LRU(LRU),
    .tag_mux_sel(tag_mux_sel),
    .data_mux_sel(data_mux_sel),
    .rdata_mux_sel(rdata_mux_sel),
    .pmem_mux_sel(pmem_mux_sel)
);

cache_datapath datapath
(
    .clk(clk),
    .rst(rst),
    .mem_wdata256(mem_wdata256),
    .mem_rdata256(mem_rdata256),
    .mem_byte_enable256(mem_byte_enable256),
    .mem_address(mem_address),
    .pmem_rdata(pmem_rdata),
    .pmem_address(pmem_address),
    .pmem_wdata(pmem_wdata),
    .load_tag0(load_tag0),
    .load_data0(load_data0),
    .load_valid0(load_valid0),
    .load_dirty0(load_dirty0),
    .load_tag1(load_tag1),
    .load_data1(load_data1),
    .load_valid1(load_valid1),
    .load_dirty1(load_dirty1),
    .load_LRU(load_LRU),
    .lru_data_i(lru_data_i),
    .hit0(hit0),
    .hit1(hit1),
    .valid0(valid0),
    .valid1(valid1),
    .dirty0(dirty0),
    .dirty1(dirty1),
    .dirty0_o(dirty0_o),
    .dirty1_o(dirty1_o),
    .valid0_o(valid0_o),
    .valid1_o(valid1_o),
    .LRU(LRU),
    .tag_mux_sel(tag_mux_sel),
    .data_mux_sel(data_mux_sel),
    .rdata_mux_sel(rdata_mux_sel),
    .pmem_mux_sel(pmem_mux_sel)
);

bus_adapter bus_adapter
(
    .mem_wdata256(mem_wdata256),
    .mem_rdata256(mem_rdata256),
    .mem_wdata(mem_wdata),
    .mem_rdata(mem_rdata),
    .mem_byte_enable(mem_byte_enable),
    .mem_byte_enable256(mem_byte_enable256),
    .address(mem_address)
);

endmodule : cache
