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
logic [15:0] operands;
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

    /* check if ready bit is set upon completion */
    assert(itf.rdy == 1'b1)
    else begin
        $error ("%0d: %0t: NOT_READY error detected", `__LINE__, $time);
        report_error(NOT_READY);
    end


    itf.start <= 1'b0;

endtask : test_product


/* check reset during shift */
task test_reset_shift();
    @(tb_clk);
    /* dummy value to shift */
    operands <= 16'h0110;
    /* start multiplication */
    itf.start <= 1'b1;
    @(tb_clk);

    itf.start <= 1'b0;

    /* if we're in the middle of doing an operation, check if it's SHIFTING */
    while (itf.rdy == 1'b0) begin
        @(tb_clk);
        /* reset if SHIFTING */
        if (dut.ms.op == SHIFT) begin
            reset();
        end
    end

    /* check the ready bit after a reset */
    assert(itf.rdy == 1'b1)
    else begin
        $error ("%0d: %0t: NOT_READY error detected", `__LINE__, $time);
        report_error(NOT_READY);
    end

endtask : test_reset_shift


/* check reset during ADD */
task test_reset_add();
    @(tb_clk);
    /* dummy value to ADD */
    operands <= 16'h0110;
    /* start multiplication */
    itf.start <= 1'b1;
    @(tb_clk);

    itf.start <= 1'b0;

    /* if we're in the middle of doing an operation, check if it's ADD */
    while (itf.rdy == 1'b0) begin
        @(tb_clk);
        /* reset if ADD */
        if (dut.ms.op == ADD) begin
            reset();
        end
    end

    /* check the ready bit after a reset */
    assert(itf.rdy == 1'b1)
    else begin
        $error ("%0d: %0t: NOT_READY error detected", `__LINE__, $time);
        report_error(NOT_READY);
    end

endtask : test_reset_add


initial itf.reset_n = 1'b0;
initial begin
    reset();
    /********************** Your Code Here *****************************/
    /* assert all possible combinations while asserting start (no resets) */
    for (i = 0; i < 65536; i++) begin
        operands = i;
        test_product();
    end

    /* checks if ready bit is not set if reset during an operation */
    test_reset_add();
    test_reset_shift();

    /*******************************************************************/
    itf.finish(); // Use this finish task in order to let grading harness
                  // complete in process and/or scheduled operations
    $error("Improper Simulation Exit");
end


endmodule : testbench
`endif
