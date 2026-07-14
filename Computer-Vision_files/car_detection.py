from ultralytics import YOLO
import cv2 as cv

# Load a pretrained YOLOv8 model (e.g., YOLOv8n for a smaller and faster model)
model = YOLO('yolov8n.pt') # replace 'n' with 's','m','l', or 'x' for different sizes

cap = cv.VideoCapture(0)

while True:
    ret, frame = cap.read()
    if not ret:
        break
    
    results = model.predict(frame)

    for result in results:
        boxes = result.boxes
        for box in boxes:
            bounding_box = box.xyxy[0].cpu().numpy()  # Get bounding box coordinates
            print(bounding_box)
            confidence = box.conf[0]

            class_id = int(box.cls[0])
            object = model.names[class_id]
            print(object, confidence)

    image = results[0].plot()
    cv.imshow('results', image)

    if cv.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv.destroyAllWindows()