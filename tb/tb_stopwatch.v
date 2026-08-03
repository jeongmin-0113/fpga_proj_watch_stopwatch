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

module tb_tick_gen_100hz ();

    reg clk, reset;
    wire o_tick;

    tick_gen_100hz dut (
        .clk(clk),
        .reset(reset),
        .o_tick(o_tick)
    );

    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        reset = 1;
        #10;
        reset = 0;

        #(1_000_000 * 10 * 2);
        $stop;
    end
endmodule

module tb_time_counter ();

    reg clk, reset;
    reg mode, runstop, clear;
    wire [6:0] time_cnt_msec;
    wire [5:0] time_cnt_sec;
    wire [5:0] time_cnt_min;
    wire o_tick, o_tick_sec, o_tick_min, o_tick_hour;

    tick_gen_100hz dut (
        .clk(clk),
        .reset(reset),
        .o_tick(o_tick)
    );

    time_counter #(100) dut_msec (
        .clk(clk),
        .reset(reset),
        .i_tick(o_tick),
        .mode(mode),
        .run_stop(runstop),
        .clear(clear),
        .time_cnt(time_cnt_msec),
        .o_tick(o_tick_msec)
    );

    time_counter #(60) dut_sec (
        .clk(clk),
        .reset(reset),
        .i_tick(o_tick_msec),
        .mode(mode),
        .run_stop(runstop),
        .clear(clear),
        .time_cnt(time_cnt_sec),
        .o_tick(o_tick_sec)
    );

    time_counter #(60) dut_min (
        .clk(clk),
        .reset(reset),
        .i_tick(o_tick_sec),
        .mode(mode),
        .run_stop(runstop),
        .clear(clear),
        .time_cnt(time_cnt_min),
        .o_tick(o_tick_min)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        runstop = 0;
        clear = 0;
        mode = 0;
        #10;
        reset   = 0;
        runstop = 1;

        #(1_000_000 * 10 * 100 * 60 * 60);
        $stop;
    end

endmodule

module tb_stopwatch ();

    reg clk, reset;
    reg mode, runstop, clear;
    wire [6:0] msec;
    wire [5:0] sec;
    wire [5:0] min;
    wire [4:0] hour;

    parameter TICK_DELAY = 1_000_000 * 10;

    stopwatch_datapath dut (
        .clk(clk),
        .reset(reset),
        .runstop(runstop),
        .clear(clear),
        .mode(mode),
        .m_sec(msec),
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
        #10;
        reset   = 0;
        runstop = 1;

        #(TICK_DELAY * 10);
        $stop;
    end

endmodule

module tb_fnd_controller ();
    parameter TICK_DELAY = 1_000_000 * 10;

    reg clk, reset;
    reg display_mode;
    reg [1:0] sw;
    reg [1:0] state;
    reg mode, runstop, clear;
    wire [6:0] msec;
    wire [5:0] sec;
    wire [5:0] min;
    wire [4:0] hour;
    wire [3:0] fnd_com;
    wire [7:0] fnd_data;
    wire [3:0] state_out;

    stopwatch_datapath dut (
        .clk(clk),
        .reset(reset),
        .runstop(runstop),
        .clear(clear),
        .mode(mode),
        .m_sec(msec),
        .sec(sec),
        .min(min),
        .hour(hour)
    );

    fnd_controller dut_fnd (
        .clk(clk),
        .reset(reset),
        .msec(msec),
        .sec(sec),
        .min(min),
        .hour(hour),
        .state(state),
        .sw(sw),
        .display_mode(0),  // sw[0] -> 0=초/1=시간 선택
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );


    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        runstop = 1;
        clear = 0;
        mode = 0;
        state = 2'b01;
        sw = 2'b10;
        #10 reset = 0;


        display_mode = 0;
        #TICK_DELAY;

        display_mode = 1;
        #TICK_DELAY $stop;
    end
endmodule
