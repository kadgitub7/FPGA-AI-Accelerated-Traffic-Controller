import time
import numpy as np
import csv
import serial
from ultralytics import YOLO
import cv2 as cv

N_LANES = 4
START_SIGNAL = 0xAA
USE_CSV = False

ser = serial.Serial('COM5', 115200, timeout=2.0)

time.sleep(2)  # Wait for connection to stabilize

model = YOLO('yolov8n.pt') # replace 'n' with 's','m','l', or 'x' for different sizes

cap = cv.VideoCapture(0)

lane1_box = [0,0,320,320]
lane2_box = [320,0,639,320]
lane3_box = [320,320,639,639]
lane4_box = [0,320,320,639]

lane_count_total = [0,0,0,0]

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

    while True:
        ret, frame = cap.read()
        if not ret:
            break
        
        results = model.predict(frame)

        for result in results:
            boxes = result.boxes
            lane_count_current = [0,0,0,0]
            for box in boxes:
                bounding_box = box.xyxy[0].cpu().numpy()  # Get bounding box coordinates
                print(bounding_box)
                confidence = box.conf[0]

                class_id = int(box.cls[0])
                object = model.names[class_id]
                if object == 'car':
                    print("found a car")
                    car_locationX = (bounding_box[0] + bounding_box[2]) / 2
                    car_locationY = (bounding_box[1] + bounding_box[3]) / 2
                    print(car_locationX, car_locationY)
                    if car_locationX > lane1_box[0] and car_locationX < lane1_box[2] and car_locationY > lane1_box[1] and car_locationY < lane1_box[3]:
                        print("Car detected in Lane 1")
                        lane_count_current[0] += 1
                    elif car_locationX > lane2_box[0] and car_locationX < lane2_box[2] and car_locationY > lane2_box[1] and car_locationY < lane2_box[3]:
                        print("Car detected in Lane 2")
                        lane_count_current[1] += 1
                    elif car_locationX > lane3_box[0] and car_locationX < lane3_box[2] and car_locationY > lane3_box[1] and car_locationY < lane3_box[3]:
                        print("Car detected in Lane 3")
                        lane_count_current[2] += 1
                    elif car_locationX > lane4_box[0] and car_locationX < lane4_box[2] and car_locationY > lane4_box[1] and car_locationY < lane4_box[3]:
                        print("Car detected in Lane 4")
                        lane_count_current[3] += 1
                    else:
                        print("Car detected in no designated lane")
                    print(object, confidence)
                    print("Lane Counts: ", lane_count_current)
                lane_count_total = lane_count_current
                print(lane_count_total)
                send_to_fpga(lane_count_total)
                time.sleep(2)

                '''
                # Main loop to simulate traffic light control
                while True:
                    # getting car counts
                    counter = 0
                    for row in csv_reader:
                        if counter == next_lane_count:
                            if(USE_CSV):
                                lane_count = row
                            else:
                                lane_count = lane_count_current
                            break
                        else:
                            counter += 1
                    # Send the next traffic light state to the FPGA
                    send_to_fpga(lane_count)
                    next_lane_count += 1  # Increment the next lane count for the next iteration
            
                    # Get the current traffic light state from the FPGA
                    # The transmission from teh FPGA is going to Arduino now
                    #traffic_light_state = receive_from_fpga()
            
                    # add user controlled quit button
                    if next_lane_count == 60:
                        break
                    # Wait for a certain period before the next iteration
                    time.sleep(2)  # Adjust the sleep time as needed
                    '''
        image = results[0].plot()
        cv.imshow('results', image)

        if cv.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv.destroyAllWindows()
    ser.close()

if __name__ == "__main__":
    main()