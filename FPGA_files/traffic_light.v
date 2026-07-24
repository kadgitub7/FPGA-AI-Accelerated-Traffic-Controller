module traffic_light(
    input clk,
    input reset,
    input input_ready,      // Triggered when a new UART byte packet is received
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
    reg next_direction; 
    reg complete;
    
    // Shortened for responsive testing with Python script loops
    localparam [29:0] MIN_GREEN = 29'd3000000000;   // ~3s at 100MHz
    localparam [29:0] MAX_GREEN = 30'd10000000000;  // ~10s at 100MHz
    localparam [5:0]  SWITCH_THRESHOLD = 6'd2; 

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

    always @(posedge clk) begin
        if (reset) begin
            current_state <= IDLE;
            last_light_1 <= 2'b10;
            last_light_2 <= 2'b00;
            counter <= 0;
            green_timer <= 0;
            direction <= 1'b1;
            next_direction <= 1'b1;
            complete <= 1'b0;
        end else begin
            current_state <= next_state;
            complete <= 1'b0; // Default to 0 (one-shot pulse)

            // CRITICAL FIX: Whenever Python sends data, force an immediate reply transmission
            if (input_ready) begin
                complete <= 1'b1;
            end

            // Counter for WAIT_3 state
            if (next_state == WAIT_3)
                counter <= counter + 1;
            else
                counter <= 0;

            // Green timer management
            if (next_state == IDLE)
                green_timer <= green_timer + 1;
            else if (next_state == SIGN_1_GREEN || next_state == SIGN_1_RED)
                green_timer <= 0;

            // Direction switching evaluation based on lane counts
            if (green_timer < MAX_GREEN) begin
                if (current_state == IDLE && next_state == YELLOW) begin
                    if (lane2 + lane4 > 0 && lane1 + lane3 == 0)
                        next_direction <= 1'b0;
                    else if (lane2 + lane4 > lane1 + lane3)
                        next_direction <= 1'b0;
                    else
                        next_direction <= 1'b1;
                end
            end
            
            if (green_timer >= MAX_GREEN && (direction && lane2 + lane4 > 0)) begin
                next_direction <= 1'b0;
            end else if (green_timer >= MAX_GREEN && (!direction && lane1 + lane3 > 0)) begin
                next_direction <= 1'b1;
            end

            // Light output assignments based on state
            case (next_state)
                SIGN_1_GREEN: begin
                    last_light_1 <= 2'b10;
                    last_light_2 <= 2'b00;
                    direction <= 1'b1;
                end
                SIGN_1_RED: begin
                    last_light_1 <= 2'b00;
                    last_light_2 <= 2'b10;
                    direction <= 1'b0;
                end
                YELLOW: begin
                    if (direction) begin
                        last_light_1 <= 2'b01;
                        last_light_2 <= 2'b00;
                    end else begin
                        last_light_1 <= 2'b00;
                        last_light_2 <= 2'b01;
                    end
                end
                ALL_RED: begin
                    last_light_1 <= 2'b00;
                    last_light_2 <= 2'b00;
                end
                default: ;
            endcase
        end
    end

    // Combinational next-state logic
    always @(*) begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (green_timer < MIN_GREEN) begin
                    next_state = IDLE;
                end else if (lane1 + lane2 + lane3 + lane4 == 0) begin
                    next_state = IDLE;
                end else if (green_timer >= MAX_GREEN && (direction && lane2 + lane4 > 0)) begin
                    next_state = YELLOW;
                end else if (green_timer >= MAX_GREEN && (!direction && lane1 + lane3 > 0)) begin
                    next_state = YELLOW;
                end else if (lane1 + lane3 > 0 && lane2 + lane4 == 0) begin
                    next_state = direction ? IDLE : YELLOW;
                end else if (lane2 + lane4 > 0 && lane1 + lane3 == 0) begin
                    next_state = !direction ? IDLE : YELLOW;
                end else if (lane1 + lane3 >= lane2 + lane4 + SWITCH_THRESHOLD) begin
                    next_state = direction ? IDLE : YELLOW;
                end else if (lane2 + lane4 >= lane1 + lane3 + SWITCH_THRESHOLD) begin
                    next_state = !direction ? IDLE : YELLOW;
                end else begin
                    next_state = IDLE;
                end
            end

            YELLOW: next_state = WAIT_3;

            WAIT_3: begin
                if (counter >= MIN_GREEN)
                    next_state = ALL_RED;
                else
                    next_state = WAIT_3;
            end

            ALL_RED: begin
                next_state = next_direction ? SIGN_1_GREEN : SIGN_1_RED;
            end

            SIGN_1_GREEN: next_state = IDLE;
            SIGN_1_RED:   next_state = IDLE;

            default: next_state = IDLE;
        endcase
    end
endmodule