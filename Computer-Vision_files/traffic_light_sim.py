import time
import numpy as np
import csv
import serial

N_LANES = 4
START_SIGNAL = 0xAA

ser = serial.Serial('COM5', 115200, timeout=2.0)

time.sleep(2)  # Wait for connection to stabilize

def features_to_uart_bytes(features):
    packed_byte = 0

    for feat_j in range(4):
        val = int(features[feat_j])

        if not 0 <= val <= 3:
            raise ValueError(
                f"Lane {feat_j} value {val} is outside 2-bit range 0-3"
            )

        shift = (3 - feat_j) * 2
        packed_byte |= val << shift

    return bytes([packed_byte])

def send_to_fpga(lane_count):
    payload_bytes = features_to_uart_bytes(lane_count)
    print("Sending:", bytes([START_SIGNAL]) + payload_bytes)
    ser.reset_output_buffer()
    ser.write(bytes([START_SIGNAL]) + payload_bytes)
    ser.flush()

def receive_from_fpga():
    print("Listening for incoming UART data...")
    n_expected = 2  # Expecting light_1 and light_2 bytes
    start = time.time()
    response = b''
    while len(response) < n_expected and (time.time() - start) < 3.0:
        if ser.in_waiting > 0:
            response += ser.read(ser.in_waiting)
        time.sleep(0.05)
    
    print("Received:", response)
    return response

def main():
    next_lane_count = 0  # Initialize the next lane count
    lane_count = [0,0,0,0]
    with open('FPGA-AI-Accelerated-Traffic-Controller\\Computer-Vision_files\\lane_count_sim.csv', mode='r', encoding='utf-8') as file:
        # Create a reader object
        csv_reader = list(csv.reader(file))


    # Main loop to simulate traffic light control
    while True:
        counter = 0
        for row in csv_reader:
            if counter == next_lane_count:
                lane_count = row
                break
            else:
                counter += 1

        # Send the next traffic light state to the FPGA
        send_to_fpga(lane_count)
        next_lane_count += 1  # Increment the next lane count for the next iteration

        # Get the current traffic light state from the FPGA
        traffic_light_state = receive_from_fpga()
        print(traffic_light_state)

        # add user controlled quit button
        if next_lane_count == 30:
            break
        # Wait for a certain period before the next iteration
        time.sleep(5)  # Adjust the sleep time as needed
    ser.close()

if __name__ == "__main__":
    main()