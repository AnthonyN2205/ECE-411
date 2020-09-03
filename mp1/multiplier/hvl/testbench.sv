import mult_types::*;

`ifndef testbench
`define testbench
module testbench(multiplier_itf.testbench itf);

add_shift_multiplier dut (
    .clk_i          ( itf.clk          ),
    .reset_n_i      ( itf.reset_n      ),
    .multiplicand_i ( itf.multiplicand ),
    .multiplier_i   ( itf.multiplier   ),
    .start_i        ( itf.start        ),
    .ready_o        ( itf.rdy          ),
    .product_o      ( itf.product      ),
    .done_o         ( itf.done         )
);

assign itf.mult_op = dut.ms.op;
default clocking tb_clk @(negedge itf.clk); endclocking

// DO NOT MODIFY CODE ABOVE THIS LINE

/* Uncomment to "monitor" changes to adder operational state over time */
initial $monitor("dut-op: time: %0t op: %s", $time, dut.ms.op.name);


// Resets the multiplier
task reset();
    itf.reset_n <= 1'b0;
    ##5;
    itf.reset_n <= 1'b1;
    ##1;
endtask : reset

// error_e defined in package mult_types in file ../include/types.sv
// Asynchronously reports error in DUT to grading harness
function void report_error(error_e error);
    itf.tb_report_dut_error(error);
endfunction : report_error


/* product result is 2*width_p bits == 16 bits */
logic [15:0] expected_results;
/* top 8 bits used for op1 --- bottom 8 bits used for op2 */
logic [15:0] operands = 16'b0;
assign itf.multiplicand = operands[15:8];
assign itf.multiplier = operands[7:0];
/* expected results of op1 * op2 */
assign expected_results = itf.multiplicand * itf.multiplier;

int i;


/* check output of multipler 
 *
 * if ready signal = 0 after reset, report NOT_READY
 * if ready signal = 0 after finished (itf.done == 1), report NOT_READY
 *
 */
task test_product();
    @(tb_clk);

    /* set start to 1 to begin new multiplcation */
    itf.start <= 1'b1;
    /* wait until multipler is done */
    @(posedge itf.done);
    /* report error if multipler result is not the same as expected */
    assert(itf.product == expected_results)
    else begin
        $error ("%0d: %0t: BAD_PRODUCT error detected", `__LINE__, $time);
        report_error(BAD_PRODUCT);
    end

    /* check if ready bit is set after being done */
    assert(itf.rdy == 1'b1)
    else begin
        $error ("%0d: %0t: NOT_READY error detected", `__LINE__, $time);
        report_error(NOT_READY);
    end

    /* perform reset to check ready bit */
    @(tb_clk);
    itf.reset_n <= 1'b0;      // active low reset
    ##5;
    itf.reset_n <= 1'b1;
    ##1

    /* check the ready bit after a reset */
    assert(itf.rdy == 1'b1)
    else begin
        $error ("%0d: %0t: NOT_READY error detected", `__LINE__, $time);
        report_error(NOT_READY);
    end

    @(tb_clk);
    /* increment operand */
    operands <= operands + 16'b1;

endtask

initial itf.reset_n = 1'b0;
initial begin
    reset();
    /********************** Your Code Here *****************************/
    /* coverage 1: assert all possible combinations without resets */
    for (i = 0; i < 17'h1000; i++) begin
        test_product();
    end

    /*******************************************************************/
    itf.finish(); // Use this finish task in order to let grading harness
                  // complete in process and/or scheduled operations
    $error("Improper Simulation Exit");
end


endmodule : testbench
`endif
