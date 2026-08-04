`timescale 1ns / 1ps

module tb_stopwatch_time_counter ();

    parameter TICK_DELAY = 1_000_000 * 10;

    reg clk;
    reg reset;
    reg btn_L;  // runstop(s) / 자리변경(w) 
    reg btn_R;  // clear(s) / 자리변경(w)
    reg btn_UP;  // mode(s) / up(w)
    reg btn_DOWN;  // option(s) / down(w)
    reg  [1:0] sw;       // sw[0]: 0-초:밀리초/1-시:분 sw[1]: 0-stopwatch/1-watch
    wire [3:0] fnd_com;
    wire [7:0] fnd_data;
    wire led;  // indicator

    top_stopwatch U_TOP_TIME_COUNTER (
        .clk(clk),
        .reset(reset),
        .btn_L(btn_L),  // runstop(s) / 자리변경(w) 
        .btn_R(btn_R),  // clear(s) / 자리변경(w)
        .btn_UP(btn_UP),  // mode(s) / up(w)
        .btn_DOWN(btn_DOWN),  // option(s) / down(w)
        .sw(sw),  // sw[0]: 0-초:밀리초/1-시:분 sw[1]: 0-stopwatch/1-watch
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

        #10 reset = 0;
        #10 btn_L = 1;
        #(TICK_DELAY * 5); btn_L = 0;
        $finish;
    end

endmodule
