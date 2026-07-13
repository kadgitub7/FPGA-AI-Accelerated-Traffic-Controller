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

