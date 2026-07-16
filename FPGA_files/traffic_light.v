module traffic_light(
    input clk,
    input reset,
    input [5:0] lane1,
    input [5:0] lane2,
    input [5:0] lane3,
    input [5:0] lane4,
    output reg [1:0] light_1,
    output reg [1:0] light_2
);

    reg last_light_1, last_light_2;
    reg [29:0]counter;

    localparam [2:0] IDLE = 3'b000,
                     SIGN_1_GREEN = 3'b001,
                     SIGN_1_RED = 3'b010,
                     YELLOW = 3'b011,
                     ALL_RED = 3'b100;
                     WAIT_3 = 3'b101;
    
    reg [2:0] current_state;
    reg [2:0] next_state;

    always@(posedge clk) begin
        if (reset) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end

        light_1 <= last_light_1;
        light_2 <= last_light_2;
        case (current_state)
            IDLE: begin
                if (lane1 + lane2 + lane3 + lane4 == 0) begin
                    next_state <= IDLE;
                end else if (lane1 + lane3 > 0 && lane2 + lane4 == 0) begin
                    next_state <= SIGN_1_GREEN;
                end else if (lane2 + lane4 > 0 && lane1 + lane3 == 0) begin
                    next_state <= SIGN_1_RED;
                end else if (lane1 + lane3 > lane2 + lane4) begin
                    next_state <= SIGN_1_GREEN;
                end else if (lane2 + lane4 > lane1 + lane3) begin
                    next_state <= SIGN_1_RED;
                end else begin
                    if (last_light_1 == 2'b01) begin
                        next_state <= SIGN_1_RED;
                    end else begin
                        next_state <= SIGN_1_GREEN;
                    end
                end
            end

            SIGN_1_GREEN: begin
                if(last_light_1 == 1'b1)begin
                    next_state <= IDLE;
                end else begin
                    next_state <= YELLOW;
                end
            end

            SIGN_1_RED: begin
                if(last_light_1 == 1'b0)begin
                    next_state <= IDLE;
                end else begin
                    next_state <= YELLOW;
                end
            end

            YELLOW: begin
                if(last_light_1 == 1'b0) begin
                    //wait 3 seconds
                    light_2 <= 2'b01;
                    next_state <= WAIT_3;
                end else begin
                    light_1 <= 2'b01;
                    next_state <= WAIT_3;
                end
            end

            WAIT_3: begin
                if (counter == 29'd300000000) begin
                    counter <= 0;
                    next_state <= ALL_RED;
                end
                else begin
                    counter <= counter + 1;
                    next_state <= WAIT_3;
                end   
            end

            ALL_RED: begin
                if(last_light_1 == 2'b01) begin
                    light_1 <= 2'b00;
                    light_2 <= 2'b10;
                end else begin
                    light_1 <= 2'b10;
                    light_2 <= 2'b00;
                end
                next_state <= IDLE;
            end

        endcase
    end

endmodule