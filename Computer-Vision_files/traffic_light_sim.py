import time
import numpy as np
import csv
import serial

N_LANES = 4
START_SIGNAL = 0xAA
STOP_SIGNAL = 20

ser = serial.Serial('COM4', 115200, timeout=2.0)
'''
ser = serial.Serial(
    port='COM3',      
    baudrate=115200,    
    parity=serial.PARITY_NONE,
    stopbits=serial.STOPBITS_ONE,
    bytesize=serial.EIGHTBITS,
    timeout=1         # Read timeout in seconds
)
'''
time.sleep(2)  # Wait for connection to stabilize

def features_to_uart_bytes(features: np.ndarray) -> bytes:
    packed_byte = 0
    for feat_j in range(N_LANES):
        val = int(features[feat_j]) & 0x03  # Ensure value fits in 2 bits
        shift = (N_LANES - 1 - feat_j) * 2  # Lane 0 -> shift 6, Lane 3 -> shift 0
        packed_byte |= (val << shift)
        
    return bytes([packed_byte])

def send_to_fpga(lane_count):
    # Send the traffic light state to the FPGA
    # This function should be implemented to send the data to the FPGA
    payload_bytes = features_to_uart_bytes(lane_count)
    print(payload_bytes)
    ser.write(bytes([START_SIGNAL]) + payload_bytes)
    ser.flush()


def receive_from_fpga():
    ser.reset_input_buffer()
    print("Listening for incoming UART data...")
    n_expected = 2
    start = time.time()
    response = b''
    while len(response) < n_expected and (time.time() - start) < 15.0:
        chunk = ser.read(n_expected - len(response))
        if chunk:
            response += chunk
    
    print(response)
    
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