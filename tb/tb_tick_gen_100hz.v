`timescale 1ns / 1ps

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