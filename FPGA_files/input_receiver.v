module input_receiver(
    input clk, reset,
    input rx_pin,
    input rx_byte_valid,
    input [7:0] rx_byte,
    output reg [5:0] lane1, lane2, lane3, lane4,
    output reg rx_done
);
    localparam [1:0]
        S_IDLE = 2'd0,
        S_RECEIVE = 2'd1,
        S_DONE = 2'd2;

    reg [1:0] state;

    always @(posedge clk) begin
        if (reset) begin
            state <= S_IDLE;
            lane1 <= 6'd0;
            lane2 <= 6'd0;
            lane3 <= 6'd0;
            lane4 <= 6'd0;
            rx_done <= 1'b0;
        end else begin
            rx_done <= 1'b0; // default to not done

            case(state)
                S_IDLE: begin
                    if (rx_byte_valid) begin
                        state <= S_RECEIVE;
                    end
                end

                S_RECEIVE: begin
                    if (rx_byte_valid) begin
                        lane1 <= rx_byte[7:6]; // Assuming lane1 is in bits 7-6
                        lane2 <= rx_byte[5:4]; // Assuming lane2 is in bits 5-4
                        lane3 <= rx_byte[3:2]; // Assuming lane3 is in bits 3-2
                        lane4 <= rx_byte[1:0]; // Assuming lane4 is in bits 1-0
                        // only deficit is that our maximum cars per lane is 3 (2 bits), but we can adjust the encoding if needed
                        state <= S_DONE;
                    end
                end

                S_DONE: begin
                    rx_done <= 1'b1; // signal that all lanes have been received
                    state <= S_IDLE; // go back to idle for next reception
                end

                default: state <= S_IDLE; // safety net to return to idle on unexpected state
            endcase
        end
    end

endmodule