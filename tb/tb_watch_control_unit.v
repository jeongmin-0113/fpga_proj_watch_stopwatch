`timescale 1ns / 1ps
module tb_watch_and_stopwatch_top ();
    parameter TICK_DELAY = 1_000_000 * 10;

    reg clk, reset;
    reg btn_L, btn_R, btn_UP, btn_DOWN;
    reg  [2:0] sw;

    wire [3:0] fnd_com;
    wire [7:0] fnd_data;
    wire  led;


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
        sw = 3'b010; // watch 모드
        #10; 
        reset = 0;

        #(TICK_DELAY*3); //btn_R 누름
        btn_R = 1;
        #(TICK_DELAY*3); 
        btn_R = 0;

        #(TICK_DELAY);
        btn_R = 1;
        #(TICK_DELAY*3); 
        btn_R = 0;

        #(TICK_DELAY);
        btn_R = 1;
        #(TICK_DELAY*3); 
        btn_R = 0;

        #(TICK_DELAY);
        btn_R = 1;
        #(TICK_DELAY*3); 
        btn_R = 0;

        #(TICK_DELAY);

        #(TICK_DELAY); //btn_L 누름
        btn_L = 1;
        #(TICK_DELAY*3); 
        btn_L = 0;

        #(TICK_DELAY);
        btn_L = 1;
        #(TICK_DELAY*3); 
        btn_L = 0;

        #(TICK_DELAY);
        btn_L = 1;
        #(TICK_DELAY*3); 
        btn_L = 0;

        #(TICK_DELAY);
        btn_L = 1;
        #(TICK_DELAY*3); 
        btn_L = 0;

        #(TICK_DELAY);
        btn_L = 1;
        
        
        $stop;
    end

endmodule
