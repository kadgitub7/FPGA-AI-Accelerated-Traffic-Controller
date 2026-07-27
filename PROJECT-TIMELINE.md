# PROJECT TIMELINE & OBJECTIVES

**Short Disclaimer**
This .md file is for people that want to understand what process as well as stuggles I went through to complete this project. Through this approach I will learn a lot and hit many roadblocks, which I hope to overcome. By following this file, you can see what my objectives, by path to implementation, and learning is.

## 0. Making the map
The Map in which the intersection will be modelled and the traffic light control will be managed is shown in the **Computer-Vision_files** folder named **initial_map.jpg**

There is one problem with the current design and it is that the traffic lights will not be a single pole breadboard, they need to be a larger system on top of that pole since electic connect cannot be given and controlled through the current setup.

The first step now is to make the traffic lights work and can be freely controlled through and arduino system.

## 1. Making the traffic lights and creating base model
The first step is to make a working traffic light system, this system has to allow for a set of resistors LEDs and wires as well as Arduino C++ code that controls the traffic light as it would on a real intersection.
The arduino connections to the breadboard and LEDs was all done on a software called TinkerCad before being wired in reality, so that it could be properly mapped and completed accuractely and effectively.

- One thing to note is that we need two traffic lights for this project as it is a 4 way intersection. I am stopping at 2 because the opposite lights will be the exact same, and the Arduino only has so many input and output ports.

The sequence of lights signals and times was researched online and this will be the base model that we will compare results such as througout of cars, efficiency, waitime and such with the improved computer vision/FPGA AI solution.

## 2. Identifying the cars and lanes
The next item that was completed was introducing a simple lightweight yolov8 nano model. This would be the camera and image detection software. We use the computers basic camera to get input for the model and identify through the python code what the object is.

Only cars were detected since there are other objects we are not concerned with

Next we need to only detect cars in the particularly drawn lanes. This means we need to define boundaries where the cars should be. Through inspection it was clear that we could just divide the entire map into quadrants and it would align with the lanes. The center point of the bounding boxes for the cars where used as reference points to determine if the car was in that particular lane and we keep track of how many cars are in each lane.

An image of this being tested can be seen in **Compute-Vision_files/Identifying_Lanes_Cars.png**.

## 3. Logic mapping
The logic for how we should control the traffic light in all possible scenarios is given, we need to create a condensed and simple algorithm for this now and to translate it to a Finite State Machine for the FPGA to control.

## 4. FSM Design
Started the preliminary logic for the FSM. After mapping out the different patterns and what the corresponding action should be, I have now started to map out exactly how the FSM will move, what variables are changed how we control the lights values from the inside here.

## 5. Improving the traffic control
I implemented new features like min green time and starvation period so that it is more robust and follows the mechanisms that we ideally want for the traffic light to follow. This part had a lot of issues since there were some issues pertaining to the starvation period and to resolve it took significant debugging and log checking

## 6. UART control
Now that we have a working traffic light detection system we need to hook up the conputer vision section to the FPGA and the FPGA to the Arduino UNO through UART.

## 7. Debugging
First UART signals were not correctly matched. Many times the FSM design needed to be changed as timing was not correct or signals where not being passed effectively. Additionally physical wiring was a challenge. Pins needed to be specified and then connected properly. Each wire LED, and other components were tested methododically when errors arose. Once connection was made the wrong port was used and I needed to switch from COM4 to COM5. Then python file needed to be corrected because there were two while True loops which lagged the yolo v8 computer vision model. After this the lanes where wrong, the pixel boxes we initialized first were incorrect and needed to be changed.

## 8. Testing
This is the final step. Since the entire project is now fully functional, the next step is to determine a few scenarios which we can measure against the benchmark version of the traffic light.
First I made 10 different scenarios and then measure the time it takes for the car that waits the most to get a favorable signal. I then compare these values for the regular traffic light vs the FPGA/Computer Vision traffic light.