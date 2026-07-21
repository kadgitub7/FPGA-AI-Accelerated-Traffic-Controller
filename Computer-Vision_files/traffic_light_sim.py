import time
import numpy as np
import csv
import serial

N_LANES = 4
START_SIGNAL = 10
STOP_SIGNAL = 20

ser = serial.Serial(
    port='COM3',      
    baudrate=9600,    
    parity=serial.PARITY_NONE,
    stopbits=serial.STOPBITS_ONE,
    bytesize=serial.EIGHTBITS,
    timeout=1         # Read timeout in seconds
)
time.sleep(2)  # Wait for connection to stabilize

def features_to_uart_bytes(features: np.ndarray) -> bytes:
    payload = bytearray()
    for feat_j in range(N_LANES):
        val = int(features[feat_j])
        payload.append(int(format(val,'b')))
    return bytes(payload)

def send_to_fpga(lane_count):
    # Send the traffic light state to the FPGA
    # This function should be implemented to send the data to the FPGA
    payload_bytes = features_to_uart_bytes(lane_count)
    print(payload_bytes)
    ser.write(bytes(START_SIGNAL))
    ser.write(payload_bytes)


def receive_from_fpga():
    ser.reset_input_buffer()
    print("Listening for incoming UART data...")
    if ser.in_waiting > 0:
        # Read a line of data until a newline character (\n) is received
        raw_data = ser.readline()

        # Decode bytes into a readable string
        decoded_data = raw_data.decode('utf-8').rstrip()

        print(f"Received: {decoded_data}")
            
        time.sleep(0.01)  # Tiny delay to reduce CPU usage
    
    # Receive the traffic light state from the FPGA
    # This function should be implemented to receive the data from the FPGA
    pass

def main():
    next_lane_count = 0  # Initialize the next lane count
    lane_count = [0,0,0,0]
    with open('FPGA-AI-Accelerated-Traffic-Controller\\Computer-Vision_files\\lane_count_sim.csv', mode='r', encoding='utf-8') as file:
        # Create a reader object
        csv_reader = list(csv.reader(file))


    # Main loop to simulate traffic light control
    while True:
        # Get the current traffic light state from the FPGA
        traffic_light_state = receive_from_fpga()
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

        # Wait for a certain period before the next iteration
        time.sleep(5)  # Adjust the sleep time as needed

        # add user controlled quit button
        if next_lane_count == 60:
            break
    
    ser.close()

if __name__ == "__main__":
    main()