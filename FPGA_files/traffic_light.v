module traffic_light(
    input clk,
    input reset,
    input [5:0] lane1,
    input [5:0] lane2,
    input [5:0] lane3,
    input [5:0] lane4,
    output [1:0] light_1,
    output [1:0] light_2,
    output dl_prediction_complete
);

    reg [1:0] last_light_1, last_light_2;
    reg [29:0] counter;
    reg [29:0] green_timer;
    reg direction;      // 1 = light_1 green, 0 = light_2 green
    reg next_direction;  // target direction after yellow/all_red transition
    reg complete;
    
    localparam [29:0] MIN_GREEN = 29'd300000000;  // minimum green hold
    localparam [29:0] MAX_GREEN = 30'd1000000000; // force switch to prevent starvation
    localparam [5:0]  SWITCH_THRESHOLD = 6'd2; // min car difference to justify switching

    localparam [2:0] IDLE         = 3'b000,
                     SIGN_1_GREEN = 3'b001,
                     SIGN_1_RED   = 3'b010,
                     YELLOW       = 3'b011,
                     ALL_RED      = 3'b100,
                     WAIT_3       = 3'b101;

    reg [2:0] current_state;
    reg [2:0] next_state;

    assign light_1 = last_light_1;
    assign light_2 = last_light_2;
    assign dl_prediction_complete = complete;

    // Sequential: state register, counter, direction tracking, and output logic
    always @(posedge clk) begin
        if (reset) begin
            current_state <= IDLE;
            last_light_1 <= 2'b10;
            last_light_2 <= 2'b00;
            counter <= 0;
            green_timer <= 0;
            direction <= 1;
            next_direction <= 1;
        end else begin
            current_state <= next_state;

            // Counter for WAIT_3
            if (next_state == WAIT_3)
                counter <= counter + 1;
            else
                counter <= 0;

            // Green timer: counts while in IDLE (green is active), resets on transition
            if (next_state == IDLE)
                green_timer <= green_timer + 1;
            else if (next_state == SIGN_1_GREEN || next_state == SIGN_1_RED)
                green_timer <= 0;

            // Capture target direction when leaving IDLE
            if (green_timer < MAX_GREEN) begin
                if (current_state == IDLE && next_state == YELLOW) begin
                    if (lane2 + lane4 > 0 && lane1 + lane3 == 0)
                        next_direction <= 0;
                    else if (lane2 + lane4 > lane1 + lane3)
                        next_direction <= 0;
                    else
                        next_direction <= 1;
                end
            end
            
            if(green_timer >= MAX_GREEN &&(direction && lane2 + lane4 > 0)) begin
                    next_direction <= 1'b0;
            end else if(green_timer >= MAX_GREEN &&(!direction && lane1 + lane3 > 0)) begin
                    next_direction <= 1'b1;
            end else
                next_direction <= next_direction;
            // Output logic
            case (next_state)
                SIGN_1_GREEN: begin
                    last_light_1 <= 2'b10;
                    last_light_2 <= 2'b00;
                    direction <= 1;
                    complete <= 1;
                end
                SIGN_1_RED: begin
                    last_light_1 <= 2'b00;
                    last_light_2 <= 2'b10;
                    direction <= 0;
                    complete <= 1;
                end
                YELLOW: begin
                    if (direction) begin
                        last_light_1 <= 2'b01;
                        last_light_2 <= 2'b00;
                    end else begin
                        last_light_1 <= 2'b00;
                        last_light_2 <= 2'b01;
                    end
                    complete <= 1;
                end
                ALL_RED: begin
                    last_light_1 <= 2'b00;
                    last_light_2 <= 2'b00;
                    complete <= 1;
                end
                // IDLE, WAIT_3: retain current light values
            endcase
        end
    end

    // Combinational next-state logic
    always @(*) begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (green_timer < MIN_GREEN) begin
                    // Hold green for minimum time before any decision
                    next_state = IDLE;
                end else if (lane1 + lane2 + lane3 + lane4 == 0) begin
                    next_state = IDLE;
                end 
                // Force switch to prevent starvation
                else if(green_timer >= MAX_GREEN &&(direction && lane2 + lane4 > 0)) begin
                    next_state = YELLOW;
                    //next_direction = 1'b0;
                end
                
                else if(green_timer >= MAX_GREEN &&(!direction && lane1 + lane3 > 0)) begin
                    next_state = YELLOW;
                    //next_direction = 1'b1;
                end else if (lane1 + lane3 > 0 && lane2 + lane4 == 0) begin
                    if (direction)
                        next_state = IDLE;
                    else
                        next_state = YELLOW;
                end else if (lane2 + lane4 > 0 && lane1 + lane3 == 0) begin
                    if (!direction)
                        next_state = IDLE;
                    else
                        next_state = YELLOW;
                end else if (lane1 + lane3 >= lane2 + lane4 + SWITCH_THRESHOLD) begin
                    if (direction)
                        next_state = IDLE;
                    else
                        next_state = YELLOW;
                end else if (lane2 + lane4 >= lane1 + lane3 + SWITCH_THRESHOLD) begin
                    if (!direction)
                        next_state = IDLE;
                    else
                        next_state = YELLOW;
                end else begin
                    // Difference below threshold - keep current direction
                    next_state = IDLE;
                end
            end

            YELLOW: next_state = WAIT_3;

            WAIT_3: begin
                if (counter >= 29'd300000000)
                    next_state = ALL_RED;
                else
                    next_state = WAIT_3;
            end

            ALL_RED: begin
                if (next_direction)
                    next_state = SIGN_1_GREEN;
                else
                    next_state = SIGN_1_RED;
            end

            SIGN_1_GREEN: next_state = IDLE;
            SIGN_1_RED:   next_state = IDLE;

            default: next_state = IDLE;
        endcase
    end
endmodule
