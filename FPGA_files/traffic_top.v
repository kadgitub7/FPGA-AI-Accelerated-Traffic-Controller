module traffic_top(
    input clk,
    input reset,
    input wire rx_pin,
    output wire tx_pin,
    output [1:0] light_1,
    output [1:0] light_2
);
    localparam CLOCKS_PER_BIT = 868;

    wire [7:0] rx_byte;
    wire       rx_byte_valid;

    wire        tx_active;
    wire        tx_serial;
    wire        tx_done;
    
    wire [7:0]   sender_tx_data;
    wire         sender_tx_start;
    wire         sender_done;
    
    wire dl_prediction_complete, dl_input_ready;
    
    wire [5:0] lane1, lane2, lane3, lane4;
    
    // Note: light_1 and light_2 outputs are driven by traffic_light_inst

    traffic_light traffic_light_inst (
        .clk(clk),
        .reset(reset),
        .input_ready(dl_input_ready), // <--- CONNECTED HERE
        .lane1(lane1),
        .lane2(lane2),
        .lane3(lane3),
        .lane4(lane4),
        .light_1(light_1),
        .light_2(light_2),
        .dl_prediction_complete(dl_prediction_complete)
    );

    uart_rx #(.CLKS_PER_BIT(CLOCKS_PER_BIT)) u_uart_rx (
        .i_Clock(clk), .i_Rx_Serial(rx_pin),
        .o_Rx_Byte(rx_byte), .o_Rx_DV(rx_byte_valid)
    );

    uart_tx #(.CLKS_PER_BIT(CLOCKS_PER_BIT)) u_uart_tx (
        .i_Clock(clk), .i_Tx_DV(sender_tx_start), .i_Tx_Byte(sender_tx_data),
        .o_Tx_Active(tx_active), .o_Tx_Serial(tx_serial), .o_Tx_Done(tx_done)
    );

    result_sender u_result_sender (
        .clk(clk), .reset(reset),
        .send_start(dl_input_ready),
        .light_1(light_1), .light_2(light_2),
        .tx_busy(tx_active),
        .tx_data(sender_tx_data), .tx_start(sender_tx_start),
        .done(sender_done)
    );

    input_receiver u_input_receiver (
        .clk(clk), .reset(reset),
        .rx_pin(rx_pin),
        .rx_byte_valid(rx_byte_valid),
        .rx_byte(rx_byte),
        .lane1(lane1), .lane2(lane2), .lane3(lane3), .lane4(lane4),
        .rx_done(dl_input_ready)
    );

    assign tx_pin = tx_serial;

endmodule