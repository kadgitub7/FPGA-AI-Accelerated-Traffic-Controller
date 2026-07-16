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
        $monitor("Time: %0t | Lane1: %b | Lane2: %b | Lane3: %b | Lane4: %b | Light1: %b | Light2: %b", $time, lane1, lane2, lane3, lane4, light_1, light_2);
        clk = 0;
        reset = 1;
        lane1 = 6'b000000;
        lane2 = 6'b000000;
        lane3 = 6'b000000;
        lane4 = 6'b000000;

        #10 reset = 0;

        // Test case 1: No cars in any lane
        #10 lane1 = 6'b000000; lane2 = 6'b000000; lane3 = 6'b000000; lane4 = 6'b000000;

        // Test case 2: Cars in lane1 and lane3
        #10 lane1 = 6'b000001; lane2 = 6'b000000; lane3 = 6'b000001; lane4 = 6'b000000;

        // Test case 3: Cars in lane2 and lane4
        #10 lane1 = 6'b000000; lane2 = 6'b000001; lane3 = 6'b000000; lane4 = 6'b000001;

        // Test case 4: More cars in lanes 1 and 3 than lanes 2 and 4
        #10 lane1 = 6'b000010; lane2 = 6'b000001; lane3 = 6'b000010; lane4 = 6'b000001;

        // Test case 5: More cars in lanes 2 and 4 than lanes 1 and 3
        #10 lane1 = 6'b000001; lane2 = 6'b000010; lane3 = 6'b000001; lane4 = 6'b000010;

        // Test case 6: Equal number of cars in all lanes
        #10 lane1 = 6'b000001; lane2 = 6'b000001; lane3 = 6'b000001; lane4 = 6'b000001;

        // Finish simulation after some time
        #100 $finish;
    end
endmodule