`timescale 1ns / 1ps

module tb_stopwatch_save_load ();

    parameter TICK_DELAY = 1_000_000 * 10;

    reg clk, reset;
    reg btn_L, btn_R, btn_UP, btn_DOWN;
    reg [2:0] sw;
    wire [3:0] fnd_com;
    wire [7:0] fnd_data;
    wire led;

    top_stopwatch dut (
        .clk(clk),
        .reset(reset),
        .btn_L(btn_L),  // runstop(s) / 자리변경(w) 
        .btn_R(btn_R),  // clear(s) / 자리변경(w)
        .btn_UP(btn_UP),  // mode(s) / up(w)
        .btn_DOWN(btn_DOWN),  // option(s) / down(w)
        .sw(sw),        // sw[0]: 0-초:밀리초/1-시:분 sw[1]: 0-stopwatch/1-watch, sw[2] : watch의 12시간제
        .fnd_com(fnd_com),
        .fnd_data(fnd_data),
        .led(led)  // indicator
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        btn_L = 0;
        btn_R = 0;
        btn_UP = 0;
        btn_DOWN = 0;
        sw = 3'b000;
        #10;
        reset = 0;

        #7;  // run
        btn_L = 1;
        #(TICK_DELAY * 5);
        #6;
        btn_L = 0;

        #(TICK_DELAY * 1_000_000);

        #6;  // stop
        btn_L = 1;
        #(TICK_DELAY * 5);
        btn_L = 0;

        #6;  // save
        btn_DOWN = 1;
        #(TICK_DELAY * 5);
        btn_DOWN = 0;

        #TICK_DELAY;

        #7;  // clear
        btn_R = 1;
        #(TICK_DELAY * 5);
        btn_R = 0;

        #(TICK_DELAY * 10);

        #6;  // load
        btn_DOWN = 1;
        #TICK_DELAY;
        btn_DOWN = 0;
        #(TICK_DELAY);

        #6;  // run
        btn_L = 1;
        #(TICK_DELAY * 10);
        btn_L = 0;
        $stop;

    end
endmodule