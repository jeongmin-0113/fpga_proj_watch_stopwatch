`timescale 1ns / 1ps

module tb_stopwatch_save_load ();

    parameter TICK_DELAY = 1_000_000 * 10;

    reg clk, reset;
    reg runstop, clear, mode, save, load;
    wire o_is_data_saved;
    wire [6:0] m_sec;
    wire [5:0] sec, min;
    wire [4:0] hour;

    stopwatch_datapath dut (
        .clk(clk),
        .reset(reset),
        .runstop(runstop),
        .clear(clear),
        .mode(mode),
        .save(save),
        .load(load),
        .o_is_data_saved(o_is_data_saved),
        .m_sec(m_sec),
        .sec(sec),
        .min(min),
        .hour(hour)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        runstop = 0;
        clear = 0;
        mode = 0;
        save = 0;
        load = 0;
        #10;
        reset   = 0;

        #7; // run
        runstop = 1;
        #(TICK_DELAY * 50);
        #6; // stop
        runstop = 0;

        #6; // save
        save = 1;
        #10;
        save = 0;

        #(TICK_DELAY);

        #6; // run
        runstop = 1;
        #(TICK_DELAY * 50);
        runstop = 0;

        #TICK_DELAY;

        #6; // load
        load = 1;
        #TICK_DELAY;
        load = 0;
        #(TICK_DELAY);

        #6; // run
        runstop = 1;
        #(TICK_DELAY * 10);
        runstop = 0;
        $stop;

    end
endmodule
