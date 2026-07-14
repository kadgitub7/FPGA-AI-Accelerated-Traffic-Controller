from ultralytics import YOLO
import cv2 as cv

# Load a pretrained YOLOv8 model (e.g., YOLOv8n for a smaller and faster model)
model = YOLO('yolov8n.pt') # replace 'n' with 's','m','l', or 'x' for different sizes

cap = cv.VideoCapture(0)

lane1_box = [0,30,50,80]
lane2_box = [20,30,70,80]
lane3_box = [40,30,90,80]
lane4_box = [60,30,110,80]

lane_count_total = [0,0,0,0]

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
                car_locationX = (bounding_box[0] + bounding_box[2]) / 2
                car_locationY = (bounding_box[1] + bounding_box[3]) / 2
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
            lane_count_total = lane_count_current
            
    image = results[0].plot()
    cv.imshow('results', image)

    if cv.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv.destroyAllWindows()