import cam_types::*;

module testbench(cam_itf itf);

cam dut (
    .clk_i     ( itf.clk     ),
    .reset_n_i ( itf.reset_n ),
    .rw_n_i    ( itf.rw_n    ),
    .valid_i   ( itf.valid_i ),
    .key_i     ( itf.key     ),
    .val_i     ( itf.val_i   ),
    .val_o     ( itf.val_o   ),
    .valid_o   ( itf.valid_o )
);

default clocking tb_clk @(negedge itf.clk); endclocking

task reset();
    itf.reset_n <= 1'b0;
    repeat (5) @(tb_clk);
    itf.reset_n <= 1'b1;
    repeat (5) @(tb_clk);
endtask

// DO NOT MODIFY CODE ABOVE THIS LINE


key_t [7:0] keys; // {0,1,2,3,4,6,7}
val_t [7:0] values; // {0,10,20,30,40,50,60,70}
key_t [7:0] overwrite_values; // {69,11,22,33,44,55,66,77}
val_t [7:0] overwrite_keys; // {10, 11, 12, 13, 14, 15, 16, 17}


/* 
 * rw_n = decides weather read(1) or write (0). **No effects if valid_i = 1 
 * valid_i = asserted when read/write performed 
 * key = key input
 * val_i = value input
 *
 */
task write(input key_t key, input val_t val);
    /* write <key,val> to cam */
    @(tb_clk);
    itf.valid_i <= 1'b1;
    itf.rw_n <= 1'b0;
    itf.key <= key;
    itf.val_i <= val;


    @(tb_clk);
    itf.valid_i <= 1'b0;


endtask

/*
 * rw_n = decides weather read(1) or write (0). **No effects if valid_i = 1 
 * valid_i = asserted when read/write performed 
 * key = key input
 * val_o = val of key
 * valid_o = if value in val_o is correct
 *
 */
task read(input key_t key, input val_t val);
    /* set for read */
    @(tb_clk);
    itf.valid_i <= 1'b1;
    itf.rw_n <= 1'b1;
    itf.key <= key;

    /* check if the value matches */
    @(tb_clk);
    assert(itf.val_o == val)
    else begin
        itf.tb_report_dut_error(READ_ERROR);
        $error("%0t TB: Read %0d, expected %0d", $time, itf.val_o, val);
    end

    @(tb_clk);
    itf.valid_i <= 1'b0;

endtask




/* does consecutive writes to same key */
task consec_writes(input key_t key, input val_t val);
    /* write */
    @(tb_clk);
    itf.valid_i <= 1'b1;
    itf.rw_n <= 1'b0;
    itf.key <= key;
    itf.val_i <= val;

    /* write */
    @(tb_clk);
    itf.valid_i <= 1'b1;
    itf.rw_n <= 1'b0;
    itf.key <= key;
    itf.val_i <= val + 10;

    @(tb_clk);
    itf.valid_i <= 1'b0;
endtask


/* does a read-write in consecutuive cycles */
task consec_write_read(input key_t key, input val_t val);
    /* write */
    @(tb_clk);
    itf.valid_i <= 1'b1;
    itf.rw_n <= 1'b0;
    itf.key <= key;
    itf.val_i <= val;

    /* read */
    @(tb_clk);
    itf.valid_i <= 1'b1;
    itf.rw_n <= 1'b1;
    itf.key <= key;

    /* check if value outputed is the expected val */
    @(tb_clk);
    assert(itf.val_o == val)
    else begin
        $error("%0t TB: Read %0d, expected %0d", $time, itf.val_o, val);
    end

    @(tb_clk);
    itf.valid_i <= 1'b0;

endtask



/* start testbench */
initial begin
    $display("Starting CAM Tests");

    for (int i = 0; i < 8; i++) begin
        keys[i] = i;
        values[i] = i * 10;
        overwrite_values[i] = i * 11;
        overwrite_keys[i] = i + 10;
    end
    overwrite_values[0] = 69;


    reset();
    /************************** Your Code Here ****************************/
    // Feel free to make helper tasks / functions, initial / always blocks, etc.
    // Consider using the task skeltons above
    // To report errors, call itf.tb_report_dut_error in cam/include/cam_itf.sv

    /* fill CAM with initial values */
    for (int i = 0; i < 8; i++) begin
        write(overwrite_keys[i] , overwrite_values[i]);
    end

    /* evict previous values */
    for (int i = 0; i < 8; i++) begin
        write(keys[i], values[i]);
    end

    /* read the new values */
    for (int i = 0; i < 8; i++) begin
        read(keys[i], values[i]);
    end
    
    /* empty CAM to test new operations */
    reset();

    /* test w/w and w/r on consecutive cycles */
    consec_writes(keys[0], values[0]);
    consec_write_read(keys[0], values[4]);
    
    /**********************************************************************/

    itf.finish();
end

endmodule : testbench
