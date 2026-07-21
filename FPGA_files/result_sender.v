module result_sender(
    input clk, reset, send_start,
    input [1:0] light_1, light_2,
    input tx_busy,

    output reg [7:0] tx_data,
    output reg tx_start,
    output reg done
);
    localparam [3:0]
        S_IDLE = 4'd0,
        S_SEND_Light_1 = 4'd1,
        S_WAIT_1 = 4'd2,
        S_SEND_Light_2 = 4'd3,
        S_WAIT_2 = 4'd4,
        S_DONE = 4'd5;

    reg [3:0] state;
    reg [1:0] latched_light_1, latched_light_2;

    // Set to 0 by each SEND state (right before pulsing tx_start).
    // Set to 1 by each WAIT state once it sees tx_busy go HIGH.
    // The WAIT state only checks !tx_busy AFTER tx_started is 1.
    // This prevents the race condition where we check !tx_busy before
    // uart_tx has had time to assert it.
    reg tx_started;

    always @(posedge clk) begin
        if (reset) begin
            state <= S_IDLE;
            tx_start <= 1'b0;
            tx_data <= 8'd0;
            done <= 1'b0;
            tx_started <= 1'b0;
        end
        else begin
            tx_start <= 1'b0;   // one-shot pulse: default OFF
            done     <= 1'b0;   // one-shot pulse: default OFF

            case(state)

                // Idle: wait for decision_logic to trigger us
                S_IDLE: begin
                    if (send_start) begin
                        latched_light_1 <= light_1;
                        latched_light_2 <= light_2;
                        state <= S_SEND_Light_1;
                    end
                end

                S_SEND_Light_1: begin
                    tx_data <= latched_light_1;
                    tx_start <= 1'b1;       // pulse for 1 cycle
                    tx_started <= 1'b0;     // reset flag before waiting
                    state <= S_WAIT_1;
                end
                S_WAIT_1: begin
                    if (!tx_started) begin
                        // Phase 1: wait for uart_tx to START (tx_busy=1)
                        if (tx_busy) tx_started <= 1'b1;
                    end
                    else if (!tx_busy) begin
                        // Phase 2: byte finished transmitting
                        state <= S_SEND_Light_2;
                    end
                end

                S_SEND_Light_2: begin
                    tx_data <= latched_light_2;
                    tx_start <= 1'b1;
                    tx_started <= 1'b0;
                    state <= S_WAIT_2;
                end
                S_WAIT_2: begin
                    if (!tx_started) begin
                        if (tx_busy) tx_started <= 1'b1;
                    end
                    else if (!tx_busy) begin
                        state <= S_DONE;
                    end
                end

                S_DONE: begin
                    done <= 1'b1;
                    state <= S_IDLE;
                end

            endcase
        end
    end
endmodule