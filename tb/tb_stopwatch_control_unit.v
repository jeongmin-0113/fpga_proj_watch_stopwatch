`timescale 1ns / 1ps

module tb_stopwatch_control_unit();
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
        
        #(TICK_DELAY*5);

        btn_L = 1; //run
        #(TICK_DELAY*5);

        btn_L = 0; //stop
        #(TICK_DELAY*5);

        btn_DOWN = 1; //save
        #(TICK_DELAY*5);

        btn_R = 1; //clear
        #(TICK_DELAY*5);

        btn_DOWN = 1; //load
        #(TICK_DELAY*5);

        btn_UP = 1; //mode
        #(TICK_DELAY*5);

        btn_L = 1; //start
        #(TICK_DELAY*5);

        btn_UP = 1; //run 중 mode - 무시됨
        #(TICK_DELAY*5);

        btn_DOWN = 1; //run 중 save - 무시됨
        #(TICK_DELAY*5);

        $stop;
    end

endmodule