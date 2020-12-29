/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and LRU arrays, comparators, muxes,
logic gates and other supporting logic. */

module cache_datapath #(
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

    /* from bus_adapter */
    input logic [255:0] mem_wdata256,
    input logic [31:0] mem_byte_enable256,

    /* from CPU */
    input logic [31:0] mem_address,

    /* from Cacheline */
    input logic [255:0] pmem_rdata, //line_o

    /* from Control */
    input logic load_tag0,
    input logic load_data0,
    input logic load_valid0,
    input logic load_dirty0,
    input logic load_tag1,
    input logic load_data1,
    input logic load_valid1,
    input logic load_dirty1,
    input logic load_LRU,
    input logic lru_data_i,
    input logic dirty0_o,
    input logic dirty1_o,
    input logic valid0_o,
    input logic valid1_o,

    /* mux select */
    input logic tag_mux_sel,
    input logic data_mux_sel,
    input logic [1:0] rdata_mux_sel,
    input logic [1:0] pmem_mux_sel,

    /* to bus adapter */
    output logic [255:0] mem_rdata256,

    /* to Cacheline */
    output logic [31:0] pmem_address, // address_i
    output logic [255:0] pmem_wdata,  // line_i

    /* to Control */
    output logic hit0,
    output logic hit1,
    output logic valid0,
    output logic valid1,
    output logic dirty0,
    output logic dirty1,
    output logic LRU
);

/*            31          8 7           5  4             0
 * mem_address [tag 24-bits| index 3-bits | offset 5-bits ]
 *
 */

logic [23:0] tag_i;
logic [2:0] index_i;
logic [255:0] datain;
logic [255:0] dataout0;
logic [255:0] dataout1;
logic [31:0] write_en0;
logic [31:0] write_en1;
logic [23:0] tag0;
logic [23:0] tag1;

assign write_en0 = load_tag0 ? {32{load_data0}} : {mem_byte_enable256 & {32{load_data0}}};
assign write_en1 = load_tag1 ? {32{load_data1}} : {mem_byte_enable256 & {32{load_data1}}};

assign tag_i = mem_address[31:8];
assign index_i = mem_address[7:5];
assign hit0 = (tag_i == tag0) & valid0;
assign hit1 = (tag_i == tag1) & valid1;

// way 0
array #(.s_index(3), .width(24)) way0_tags(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_tag0),
    .rindex(index_i),
    .windex(index_i),
    .datain(tag_i),
    .dataout(tag0)
);

array #(.s_index(3), .width(1)) way0_valid(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_valid0),
    .rindex(index_i),
    .windex(index_i),
    .datain(valid0_o),
    .dataout(valid0)
);

array #(.s_index(3), .width(1)) way0_dirty(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_dirty0),
    .rindex(index_i),
    .windex(index_i),
    .datain(dirty0_o),
    .dataout(dirty0)
);

data_array #(.s_offset(5), .s_index(3)) way0_data(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .write_en(write_en0),
    .rindex(index_i),
    .windex(index_i),
    .datain(datain),
    .dataout(dataout0)
);

// way 1
array #(.s_index(3), .width(24)) way1_tags(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_tag1),
    .rindex(index_i),
    .windex(index_i),
    .datain(tag_i),
    .dataout(tag1)
);

array #(.s_index(3), .width(1)) way1_valid(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_valid1),
    .rindex(index_i),
    .windex(index_i),
    .datain(valid1_o),
    .dataout(valid1)
);

array #(.s_index(3), .width(1)) way1_dirty(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_dirty1),
    .rindex(index_i),
    .windex(index_i),
    .datain(dirty1_o),
    .dataout(dirty1)
);

data_array #(.s_offset(5), .s_index(3)) way1_data(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .write_en(write_en1),
    .rindex(index_i),
    .windex(index_i),
    .datain(datain),
    .dataout(dataout1)
);

array #(.s_index(3), .width(1)) LRU_array(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_LRU),
    .rindex(index_i),
    .windex(index_i),
    .datain(lru_data_i),
    .dataout(LRU)
);


/* MUXES */
always_comb
begin : MUXES
    /* data to data array */
    unique case(data_mux_sel)
        1'b0: datain = pmem_rdata;
        1'b1: datain = mem_wdata256;

        default: datain = pmem_rdata;
    endcase

    /* data to cpu */
    unique case(rdata_mux_sel)
            2'b00: mem_rdata256 = dataout0;
            2'b01: mem_rdata256 = dataout1;

            default: mem_rdata256 = pmem_rdata;
    endcase

    /* address to memory */
    unique case(pmem_mux_sel)
        2'b01: pmem_address = {tag0, index_i, 5'd0};
        2'b10: pmem_address = {tag1, index_i, 5'd0};
        
        default: pmem_address = {mem_address[31:5], 5'd0};
    endcase

    /* data to memory */
    unique case (LRU)
        1'b0: pmem_wdata = dataout0;
        1'b1: pmem_wdata = dataout1;

        default: pmem_wdata = dataout0;
    endcase

end


endmodule : cache_datapath
