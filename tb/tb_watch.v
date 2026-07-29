`timescale 1ns / 1ps
module tb_watch ();
endmodule

module tb_watch_datapath ();

    parameter TICK_DELAY = 1_000_000 * 10;

    reg clk, reset;
    reg up, down;
    reg  [1:0] state;

    wire [6:0] msec;
    wire [5:0] sec;
    wire [5:0] min;
    wire [4:0] hour;

    watch_datapath dut (
        .clk(clk),
        .reset(reset),
        .up(up),
        .down(down),
        .state(state),
        .msec(msec),
        .sec(sec),
        .min(min),
        .hour(hour)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        up = 0;
        down = 0;
        state = 2'b00;
        #10;
        reset = 0;

        #(TICK_DELAY * 10);
        state = 2'b01;
        #6;
        up = 1;
        #10;
        up = 0;

        #(TICK_DELAY * 10);
        state = 2'b10;
        #6;
        up = 1;
        #10;
        up = 0;

        #(TICK_DELAY * 10);
        state = 2'b11;
        #6;
        up = 1;
        #10;
        up = 0;

        #(TICK_DELAY * 10);
        state = 2'b01;
        #6;
        down = 1;
        #10;
        down = 0;

        #(TICK_DELAY * 10);
        state = 2'b10;
        #6;
        down = 1;
        #10;
        down = 0;

        #(TICK_DELAY * 10);
        state = 2'b11;
        #6;
        down = 1;
        #10;
        down = 0;
    end
endmodule
