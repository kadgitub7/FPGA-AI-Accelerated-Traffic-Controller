`timescale 1ns / 1ps
module traffic_light_tb();
    reg clk, reset;
    reg [5:0] lane1, lane2, lane3, lane4;
    wire [1:0] light_1, light_2;

    traffic_light uut (
        .clk(clk),
        .reset(reset),
        .lane1(lane1),
        .lane2(lane2),
        .lane3(lane3),
        .lane4(lane4),
        .light_1(light_1),
        .light_2(light_2)
    );

    always #5 clk = ~clk; // 100MHz clock

    initial begin
        $monitor("Time: %0t | Next_direction = %b| State: %0d | Dir: %b | GrnT: %0d | L1: %0d L2: %0d L3: %0d L4: %0d | Light1: %b Light2: %b",
                 $time, uut.next_direction, uut.current_state, uut.direction, uut.green_timer,
                 lane1, lane2, lane3, lane4, light_1, light_2);
        clk = 0;
        reset = 1;
        lane1 = 0; lane2 = 0; lane3 = 0; lane4 = 0;

        #20 reset = 0;

        // Test 1: No cars - stays IDLE, light_1 green
        #600;

        // Test 2: Cars only in lane2 - needs to wait for MIN_GREEN before switching
        lane2 = 6'd1;
        #2000;
        
        lane2 = 6'd0;
        #200;

        // Test 3: Small difference (1 car) - should NOT switch (below threshold)
        lane1 = 6'd2; lane2 = 6'd1; lane3 = 6'd0; lane4 = 6'd0;
        #1500;

        // Test 4: Large difference - should switch (meets threshold)
        lane1 = 6'd0; lane2 = 6'd5; lane3 = 6'd0; lane4 = 6'd3;
        #2000;

        // Test 5: Starvation prevention - keep more cars on non-green side
        // light_2 should be green now; keep lane1+3 at 1 (below threshold)
        // but MAX_GREEN should eventually force a switch
        lane1 = 6'd1; lane2 = 6'd2; lane3 = 6'd0; lane4 = 6'd1;
        #5000;

        // Test 6: No cars - retain current
        lane1 = 0; lane2 = 0; lane3 = 0; lane4 = 0;
        #500;

        $finish;
    end
endmodule
