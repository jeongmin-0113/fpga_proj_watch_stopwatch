`timescale 1ns / 1ps
module tb_watch_and_stopwatch_top ();
    parameter TICK_DELAY = 1_000_000 * 10;

    reg clk, reset;
    reg btn_L, btn_R, btn_UP, btn_DOWN;
    reg  [2:0] sw;

    wire [3:0] fnd_com;
    wire [7:0] fnd_data;
    wire [1:0] led;


    top_stopwatch dut (
        .clk(clk),
        .reset(reset),
        .btn_L(btn_L),  // runstop(s) / 자리변경(w) 
        .btn_R(btn_R),  // clear(s) / 자리변경(w)
        .btn_UP(btn_UP),  // mode(s) / up(w)
        .btn_DOWN(btn_DOWN),  // option(s) / down(w)
        .sw(sw),  // sw[0]: 0-stopwatch / 1:watch
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
        
        //stopwatch모드
        #(TICK_DELAY*5);
        btn_L = 1; //start
        #(10_000);
        btn_L = 0;

        // #6;
        // btn_UP = 1;
        // #10;
        // btn_UP = 0;

        // #6;
        // btn_L = 1;
        // #10;
        // btn_L = 0;

        // #6;
        // btn_UP = 1;
        // #10;
        // btn_UP = 0;

        // #10_000;

        // #6;
        // btn_R = 1;
        // #10;
        // btn_R = 0;
        
        //watch모드
        #(TICK_DELAY * 10);
        sw = 3'b010;
        #100;

        #6;
        btn_R = 1; //hour
        #(10_000);
        btn_R = 0;

        #6;
        btn_UP = 1;  //hour증가
        #(10_000);
        btn_UP = 0;

        #(TICK_DELAY*2);
        
        //12시간제
        sw = 3'b110;
        #(TICK_DELAY*2);
        //24시간제
        sw = 3'b010;
        #(TICK_DELAY*2);


        // #6;
        // btn_L = 1;
        // #(10_000);
        // btn_L = 0;

        // #6;
        // btn_UP = 1;
        // #(10_000);
        // btn_UP = 0;

        // #(TICK_DELAY);

        // #6;
        // btn_R = 1;
        // #(10_000);
        // btn_R = 0;

        // #6;
        // btn_UP = 1;
        // #(10_000);
        // btn_UP = 0;

        // #(TICK_DELAY * 10);

        $stop;
    end

endmodule


