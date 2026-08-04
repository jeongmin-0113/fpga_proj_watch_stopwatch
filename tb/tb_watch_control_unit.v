`timescale 1ns / 1ps

module tb_watch_control_unit ();

    reg clk;
    reg reset;
    reg btn_L;
    reg btn_R;

    wire [1:0] state;

    watch_control_unit U_WATCH_CNTL_UNIT (
        .clk  (clk),
        .reset(reset),
        .btn_L(btn_L),
        .btn_R(btn_R),
        .state(state)
    );

    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        reset = 1;
        btn_R = 0;
        btn_L = 0;

        #10 reset = 0;
        

        #5 btn_R = 1;
        #10 
        btn_R = 0;
        #10
        btn_R = 1;

        #10 
        btn_R = 0;
        #10
        btn_R = 1;

        #10
        btn_R = 0;
        #10
        btn_R = 1;

        #10
        btn_R = 0;

        btn_L = 1;
        #10
        btn_L = 0;
        #10
        btn_L = 1;
         
        #10
        btn_L = 0;
        #10
        btn_L = 1;

        #10
        btn_L = 0;
        #10
        btn_L = 1;

        #10
        btn_L = 0;
        #10
        btn_L = 1;


        $stop;


    end

endmodule
