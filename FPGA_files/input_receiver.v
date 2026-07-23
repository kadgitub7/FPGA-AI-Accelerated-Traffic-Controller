module input_receiver(
    input clk, reset,
    input rx_pin,
    input rx_byte_valid,
    input [7:0] rx_byte,
    output reg [5:0] lane1, lane2, lane3, lane4,
    output reg rx_done
);
    localparam [1:0]
        S_WAIT_START = 2'd0,
        S_RECEIVE    = 2'd1,
        S_DONE       = 2'd2;

    localparam [7:0] START_SIGNAL = 8'hAA;

    reg [1:0] state;

    always @(posedge clk) begin
        if (reset) begin
            state <= S_WAIT_START;
            lane1 <= 6'd0;
            lane2 <= 6'd0;
            lane3 <= 6'd0;
            lane4 <= 6'd0;
            rx_done <= 1'b0;
        end else begin
            rx_done <= 1'b0; 

            case(state)
                S_WAIT_START: begin
                    if (rx_byte_valid && (rx_byte == START_SIGNAL)) begin
                        state <= S_RECEIVE;
                    end
                end

                S_RECEIVE: begin
                    if (rx_byte_valid) begin
                        lane1 <= rx_byte[7:6]; 
                        lane2 <= rx_byte[5:4]; 
                        lane3 <= rx_byte[3:2]; 
                        lane4 <= rx_byte[1:0]; 
                        state <= S_DONE;
                    end
                end

                S_DONE: begin
                    rx_done <= 1'b1; 
                    state <= S_WAIT_START; 
                end

                default: state <= S_WAIT_START;
            endcase
        end
    end
endmodule