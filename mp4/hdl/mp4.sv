module mp4(
    input logic clk,
    input logic rst,

    /* burst memory ports */
    output logic mem_read,
    output logic mem_write,
    output logic [63:0] mem_wdata,
    input logic [63:0] mem_rdata,
    output logic [31:0] mem_addr,
    input logic mem_resp
);

/* ICache <-> cpu*/
logic inst_read;
logic [31:0] inst_addr;
logic inst_resp;
logic [31:0] inst_rdata;

/* DCache <-> cpu*/
logic data_read;
logic data_write;
logic [3:0] data_mbe;
logic [31:0] data_addr;
logic [31:0] data_wdata;
logic data_resp;
logic [31:0] data_rdata;

/* ICache <-> Arbiter */
logic icache_resp_o;
logic [255:0] icache_line_o;
logic [31:0] icache_address_i;
logic [255:0] icache_line_i;
logic icache_read_i;
logic icache_write_i;

/* DCache <-> Arbiter */
logic dcache_resp_o;
logic [255:0] dcache_line_o;
logic [31:0] dcache_address_i;
logic [255:0] dcache_line_i;
logic dcache_read_i;
logic dcache_write_i;

/* Cacheline <--> Arbiter */
logic [255:0] line_o;
logic resp_o;
logic [255:0] line_i;
logic [31:0] address_i;
logic read_i;
logic write_i;


/* datapath */
datapath pipeline_datapath (
    .clk(clk),
    .rst(rst),
    /* Icache */
    .inst_read(inst_read),    
    .inst_addr(inst_addr),
    .inst_resp(inst_resp),
    .inst_rdata(inst_rdata),
    /* Dcache */
    .data_read(data_read),
    .data_write(data_write),
    .data_mbe(data_mbe),
    .data_addr(data_addr),
    .data_wdata(data_wdata),
    .data_resp(data_resp),
    .data_rdata(data_rdata)
);


/* I-cache */
cache Icache(
    .clk(clk),
    /* Arbiter */
    .pmem_resp(icache_resp_o), // _o signals are inputs here
    .pmem_rdata(icache_line_o),
    .pmem_address(icache_address_i),
    .pmem_wdata(icache_line_i),
    .pmem_read(icache_read_i),
    .pmem_write(icache_write_i),
    /* CPU */
    .mem_read(inst_read),
    .mem_write(1'b0),
    .mem_byte_enable_cpu(4'd0),
    .mem_address(inst_addr),
    .mem_wdata_cpu(32'd0),
    .mem_resp(inst_resp),
    .mem_rdata_cpu(inst_rdata)
);

/* D-cache */
cache Dcache(
    .clk(clk),
    /* Arbiter */
    .pmem_resp(dcache_resp_o), // _o signals are inputs here
    .pmem_rdata(dcache_line_o),
    .pmem_address(dcache_address_i),
    .pmem_wdata(dcache_line_i),
    .pmem_read(dcache_read_i),
    .pmem_write(dcache_write_i),
    /* CPU */
    .mem_read(data_read),
    .mem_write(data_write),
    .mem_byte_enable_cpu(data_mbe),
    .mem_address(data_addr),
    .mem_wdata_cpu(data_wdata),
    .mem_resp(data_resp),
    .mem_rdata_cpu(data_rdata)
);

/* Arbiter */
arbiter Arbiter(
    .clk(clk),
    .rst(rst),
    /* Icache */
    .icache_line_i(icache_line_i),
    .icache_read_i(icache_read_i),
    .icache_write_i(icache_write_i),
    .icache_address_i(icache_address_i),
    .icache_line_o(icache_line_o),
    .icache_resp_o(icache_resp_o),
    /* Dcache */
    .dcache_line_i(dcache_line_i),
    .dcache_read_i(dcache_read_i),
    .dcache_write_i(dcache_write_i),
    .dcache_address_i(dcache_address_i),
    .dcache_line_o(dcache_line_o),
    .dcache_resp_o(dcache_resp_o),
    /* Memory */
    .line_o(line_o),
    .resp_o(resp_o),
    .line_i(line_i),
    .address_i(address_i),
    .read_i(read_i),
    .write_i(write_i)
);

/* Cacheline */
cacheline_adaptor Cacheline_adaptor(
    .clk(clk),
    .reset_n(rst),
    /* Arbiter */
    .line_i(line_i),
    .line_o(line_o),
    .address_i(address_i),
    .read_i(read_i),
    .write_i(write_i),
    .resp_o(resp_o),
    /* Memory */
    .burst_i(mem_rdata),
    .burst_o(mem_wdata),
    .address_o(mem_addr),
    .read_o(mem_read),
    .write_o(mem_write),
    .resp_i(mem_resp)
);



endmodule : mp4
