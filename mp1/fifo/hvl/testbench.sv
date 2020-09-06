`ifndef testbench
`define testbench

import fifo_types::*;

module testbench(fifo_itf itf);

fifo_synch_1r1w dut (
    .clk_i     ( itf.clk     ),
    .reset_n_i ( itf.reset_n ),

    // valid-ready enqueue protocol
    .data_i    ( itf.data_i  ),
    .valid_i   ( itf.valid_i ),
    .ready_o   ( itf.rdy     ),

    // valid-yumi deqeueue protocol
    .valid_o   ( itf.valid_o ),
    .data_o    ( itf.data_o  ),
    .yumi_i    ( itf.yumi    )
);

// Clock Synchronizer for Student Use
default clocking tb_clk @(negedge itf.clk); endclocking

task reset();
    itf.reset_n <= 1'b0;
    ##(10);
    itf.reset_n <= 1'b1;
    ##(1);
endtask : reset

function automatic void report_error(error_e err); 
    itf.tb_report_dut_error(err);
endfunction : report_error

// DO NOT MODIFY CODE ABOVE THIS LINE



/* enqueue element */
task enqueue(int i);
    @(tb_clk);
    /* if queue is full */
    if (itf.rdy == 1'b0) begin
        itf.valid_i <= 1'b0;
        return;
    end

    /* valid-ready protocol */
    itf.valid_i <= 1'b1;

    /* enqueue data */
    itf.data_i <= i;

    $display("%d added", i);
    $display ("--------------");

    @(tb_clk);
    itf.valid_i <= 1'b0;
       
endtask : enqueue



/* dequeue element */
task dequeue(int j);
    @(tb_clk);

    if (itf.valid_o == 1'b0) begin
        itf.yumi <= 1'b0;
        return;
    end

    itf.yumi <= 1'b1;
    assert(itf.data_o == j)
    else begin
        $error ("%0d: %0t: INCORRECT_DATA_O_ON_YUMI_I error detected", `__LINE__, $time);
        report_error (INCORRECT_DATA_O_ON_YUMI_I);
    end 

    $display("%d removed ", itf.data_o);
    $display ("--------------");

    @(tb_clk);
    itf.yumi <= 1'b0;

endtask : dequeue

/* enqueue then dequeue 255 elements */
task both_queues(i);
    /* enqeuue the item */
    @(tb_clk);
    itf.valid_i <= 1'b1;
    itf.data_i <= i;

    @(tb_clk);
    itf.yumi <= 1'b1;

    @(tb_clk);
    itf.yumi <= 1'b0;
    itf.valid_i <= 1'b0;

endtask : both_queues


/* test reset */
task test_reset();
    @(tb_clk);

    reset();

    assert(itf.rdy == 1)
    else begin
        $error ("%0d: %0t: RESET_DOES_NOT_CAUSE_READY_O error detected", `__LINE__, $time);
        report_error (RESET_DOES_NOT_CAUSE_READY_O);
    end  
endtask : test_reset


initial begin
    reset();
    /************************ Your Code Here ***********************/
    // Feel free to make helper tasks / functions, initial / always blocks, etc.

    /* enqueue 256 items */
    for (int i = 0; i < 256; i++) begin
        $display ("--------------");
        $display ("Enqueueing: %d", i);
        enqueue(i);
    end

    /* dequeue those items */
    for (int j = 0; j < 256; j++) begin
        $display ("--------------");
        $display ("Dequeueing: %d", j);
        dequeue(j);
    end

    /* enequeue/dequeue */
    for (int i = 0; i < 255; i++) begin
        both_queues(i);
    end
    
    /* test reset */
    test_reset();
    
    /***************************************************************/
    // Make sure your test bench exits by calling itf.finish();
    itf.finish();
    $error("TB: Illegal Exit ocurred");
end

endmodule : testbench
`endif

