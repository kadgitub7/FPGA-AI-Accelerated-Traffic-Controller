# FPGA + Computer Vision Accelerated Traffic Light Controller

A full-stack embedded systems project that replaces traditional fixed-cycle traffic lights with an intelligent, real-time controller. A webcam feeds live video to a YOLOv8 object detection model that counts cars in each lane, sends those counts over UART to an FPGA running a custom finite state machine written in Verilog, which then decides the optimal signal phase and transmits the result to an Arduino that drives physical LED traffic lights.

The system was benchmarked against a standard fixed-cycle traffic light across 11 test scenarios and achieved an average **~77% reduction in worst-case wait time**.

---

## Table of Contents

- [System Overview](#system-overview)
- [Project Structure](#project-structure)
- [How It Works](#how-it-works)
  - [Computer Vision (Python)](#1-computer-vision-python)
  - [FPGA Decision Logic (Verilog)](#2-fpga-decision-logic-verilog)
  - [Arduino LED Control (C++)](#3-arduino-led-control-c)
- [Hardware and Tools](#hardware-and-tools)
- [Communication Protocol](#communication-protocol)
- [FSM Design](#fsm-design)
- [Experimental Results](#experimental-results)
- [Setup and Usage](#setup-and-usage)
- [Project Timeline](#project-timeline)

---

## System Overview

```
 Webcam                    UART (PC to FPGA)              UART (FPGA to Arduino)
   |                            |                                |
   v                            v                                v
 YOLOv8 Model  --->  Python Script  --->  FPGA (Basys 3)  --->  Arduino UNO  --->  LEDs
 (car detection)     (lane counting       (FSM decides           (receives light
                      + UART send)         signal phase)          values, drives
                                                                  physical lights)
```

The camera overlooks a physical 4-way intersection model built from cardboard with toy cars placed in drawn lanes. The Python script divides the camera frame into four quadrants (one per lane which was an easy way to measure just lane count since making boxes over the actual lanes would be really difficult), counts detected cars in each, packs those counts into a 2-byte UART packet, and sends it to the FPGA. The FPGA's finite state machine evaluates the lane distribution and decides which direction gets green. It then transmits the light states over a second UART link to the Arduino, which switches the appropriate red/yellow/green LEDs.

---

## Project Structure

```
FPGA-AI-Accelerated-Traffic-Controller/
|
|-- Computer-Vision_files/
|   |-- car_detection.py            # Standalone YOLOv8 car detection and lane assignment
|   |-- traffic_light_sim.py        # Main script: detection + UART communication with FPGA
|   |-- lane_count_sim.csv          # Pre-recorded lane counts for offline testing
|   |-- initial_map.jpg             # Photo of the physical intersection model
|   |-- Identifying_Lanes_Cars.png  # Screenshot showing YOLO detections mapped to lanes
|   |-- test_image.jpg              # Test images used during development
|   |-- test_image_2.jpg
|   |-- test_image_3.jpg
|
|-- FPGA_files/
|   |-- traffic_top.v               # Top-level module: wires together all FPGA components
|   |-- traffic_light.v             # Core FSM: decides signal phase from lane counts
|   |-- input_receiver.v            # Deserializes incoming UART bytes into lane counts
|   |-- result_sender.v             # Serializes light states and sends them over UART
|   |-- uart_rx.v                   # UART receiver (8N1, configurable baud)
|   |-- uart_tx.v                   # UART transmitter (8N1, configurable baud)
|   |-- traffic_top.xdc             # Xilinx constraints file (pin mappings for Basys 3)
|   |-- traffic_light_tb.v          # Testbench for the FSM module
|   |-- testbench_output.txt        # Simulation output log from the testbench
|   |-- logic_pipeline.txt          # Early-stage design notes for the FSM logic
|
|-- Arduino-LED-Control_files/
|   |-- Arduino_control_script.c++          # Final script: receives UART from FPGA, drives LEDs
|   |-- initial_testing/
|       |-- initial_LED_Light_script.c++    # First test: cycling a single RGB LED
|       |-- Base_trafficLight_script.c++    # Baseline fixed-cycle two-light controller
|       |-- Initial_LED_Light_test.png      # Circuit screenshot from TinkerCad
|       |-- Base_trafficLight_model.png     # Two-light circuit screenshot from TinkerCad
|       |-- Two_LED_Syncronous.png          # Synchronous two-light wiring diagram
|
|-- final_results.txt               # Full experimental results and analysis
|-- PROJECT-TIMELINE.md             # Chronological development log with objectives
|-- README.md                       # This file
|-- yolov8n.pt                      # This is the yolo v8 nano model file
```

---

## How It Works

### 1. Computer Vision (Python)

**Files:** `Computer-Vision_files/car_detection.py`, `Computer-Vision_files/traffic_light_sim.py`

- Uses **YOLOv8 Nano** (`yolov8n.pt`) from the Ultralytics library for real-time object detection
- Captures frames from the webcam using OpenCV
- Filters detections to only keep objects classified as `car`
- Divides the 640x640 frame into four quadrants that correspond to the four intersection lanes:
  - **Lane 1:** Top-left (0,0) to (320,320)
  - **Lane 2:** Top-right (320,0) to (639,320)
  - **Lane 3:** Bottom-left (0,320) to (320,639)
  - **Lane 4:** Bottom-right (320,320) to (639,639)
- Assigns each car to a lane based on the center point of its bounding box
- Packs the four lane counts (each capped at 0-3, stored as 2 bits) into a single byte and sends it over serial to the FPGA
- A CSV file (`lane_count_sim.csv`) is also included for testing purposes but can also be used to manually let the FPGA how many cars are in specific lanes

### 2. FPGA Decision Logic (Verilog)

**Files:** `FPGA_files/traffic_light.v`, `FPGA_files/traffic_top.v`, `FPGA_files/input_receiver.v`, `FPGA_files/result_sender.v`, `FPGA_files/uart_rx.v`, `FPGA_files/uart_tx.v`

The FPGA contains five modules wired together by `traffic_top.v`:

| Module | Purpose |
|--------|---------|
| `uart_rx` | Receives serial bytes from the PC at 115200 baud |
| `input_receiver` | Waits for a start signal (`0xAA`), then unpacks the next byte into four 2-bit lane counts |
| `traffic_light` | The core FSM that evaluates lane counts and decides which direction gets the green signal |
| `result_sender` | Latches the current light states and transmits them as two bytes over UART to the Arduino |
| `uart_tx` | Sends serial bytes to the Arduino at 115200 baud |

The FSM in `traffic_light.v` uses six states:

| State | Description |
|-------|-------------|
| `IDLE` | Holds current light values; evaluates whether a switch is needed |
| `YELLOW` | Transitional warning before switching |
| `WAIT_3` | Holds the yellow signal for the minimum green duration |
| `ALL_RED` | Brief all-red safety phase before switching |
| `SIGN_1_GREEN` | Sets direction 1 (lanes 1+3) to green |
| `SIGN_1_RED` | Sets direction 2 (lanes 2+4) to green |

Key parameters (configured for 100 MHz clock):
- **MIN_GREEN:** 3 seconds - minimum time a direction stays green
- **MAX_GREEN:** 10 seconds - maximum time before a forced switch (starvation prevention)
- **SWITCH_THRESHOLD:** 2 cars - the difference in car count required to trigger a direction switch

### 3. Arduino LED Control (C++)

**Files:** `Arduino-LED-Control_files/Arduino_control_script.c++`

- Receives two bytes over SoftwareSerial from the FPGA (pin D2) -> This pin was used because normal 0(rx) and 1(tx) pins were not working for FPGA -> Arduino communication
- Each byte encodes a light state: `0` = red, `1` = yellow, `2` = green
- Drives six LEDs (three per traffic light) on pins 8-13
- The `initial_testing/` folder contains the development progression:
  - `initial_LED_Light_script.c++` - First test cycling a single set of RGB LEDs
  - `Base_trafficLight_script.c++` - The fixed-cycle baseline controller (27s green, 3s yellow, 30s red) used as the comparison benchmark

---

## Hardware and Tools

| Component | Details |
|-----------|---------|
| FPGA Board | Digilent Basys 3 (Xilinx Artix-7, 100 MHz) |
| Microcontroller | Arduino UNO |
| Camera | Standard USB webcam |
| LEDs | 6x through-hole LEDs (2 sets of red/yellow/green) |
| Breadboard | 2x for physical wiring for LEDs |
| Wires and Resistors| Many for connecting LEDs with pins and resistors so there is no short circuit |
| Power supply | 1x 4 pack 1.5 AA battery holder used to power arduino |
| Physical Model | Cardboard intersection with drawn lanes, toy cars |
| Software | Vivado (synthesis), Arduino IDE, Python 3, OpenCV, Ultralytics YOLOv8 |
| Prototyping | TinkerCad (circuit design before physical wiring) |

---

## Communication Protocol

### PC to FPGA (Python to Basys 3 via USB-UART)

| Byte | Value | Purpose |
|------|-------|---------|
| 1 | `0xAA` | Start signal - tells the FPGA a data packet is coming |
| 2 | `[L1:L2:L3:L4]` | Packed byte: bits [7:6] = lane 1, [5:4] = lane 2, [3:2] = lane 3, [1:0] = lane 4 |

Each lane count is 2 bits, supporting values 0 through 3.

### FPGA to Arduino (Basys 3 Pmod to Arduino D2)

| Byte | Value | Purpose |
|------|-------|---------|
| 1 | `light_1` | State of traffic light 1 (0 = red, 1 = yellow, 2 = green) |
| 2 | `light_2` | State of traffic light 2 (0 = red, 1 = yellow, 2 = green) |

Both links operate at **115200 baud, 8N1** (8 data bits, no parity, 1 stop bit). This is needed for UART to work properly since is is asyncronous and therefore does not use a shared clock.

---

## FSM Design

The decision logic groups the four lanes into two directions:
- **Direction 1:** Lane 1 + Lane 3 (controlled by `light_1`)
- **Direction 2:** Lane 2 + Lane 4 (controlled by `light_2`)

The FSM evaluates several conditions on each input update:

1. **Minimum green time not met** - Stay in the current state, no switching allowed
2. **No cars anywhere** - Retain the current signal, do not change
3. **Cars only in one direction** - Switch green to that direction (if not already)
4. **One direction has significantly more cars** (difference >= SWITCH_THRESHOLD) - Switch to favor the busier direction
5. **MAX_GREEN exceeded with waiting cars** - Force a switch to prevent starvation on the other side
6. **Balanced or below threshold** - Maintain current state

This logic ensures the system is responsive to real-time demand while still being safe (minimum green times, yellow phases, all-red clearance intervals, and starvation prevention).

---

## Experimental Results

The system was tested across 11 scenarios comparing worst-case wait time (how long the most disadvantaged car waits for a green signal) between the AI controller and a standard fixed-cycle light (27s green / 3s yellow per direction).

| Scenario | Lane Config (L1,L2,L3,L4) | AI Wait | Fixed Wait | Reduction |
|----------|---------------------------|---------|------------|-----------|
| 1 | 2, 2, 1, 1 | 3s | 30s | 90.0% |
| 2 | 0, 2, 0, 3 | 4s | 30s | 86.7% |
| 3 | 1, 3, 0, 3 | 10s | 30s | 66.7% |
| 4 | 2, 3, 1, 1 | 10s | 30s | 66.7% |
| 5 | 1, 3, 1, 1 | 10s | 30s | 66.7% |
| 6 | 3, 1, 3, 0 | 10s | 30s | 66.7% |
| 7 | 0, 0, 0, 1 | 3s | 30s | 90.0% |
| 8a | 0, 3, 0, 2 | 3s | 30s | 90.0% |
| 8b | 3, 0, 2, 0 | 3s | 30s | 90.0% |
| 9 | 1, 3, 0, 2 | 10s | 30s | 66.7% |
| 10 | 3, 3, 3, 3 | 10s | 30s | 66.7% |

**Average reduction in worst-case wait time: ~77%**

The 10-second values correspond to the MAX_GREEN cap (starvation prevention kicking in), while the 3-4 second values show the system reacting almost immediately when traffic is lopsided or light. Full details and methodology are in `final_results.txt`.

---

## Setup and Usage

### Prerequisites

- Python 3.8+ with the following packages:
  - `ultralytics` (YOLOv8)
  - `opencv-python`
  - `pyserial`
  - `numpy`
- Xilinx Vivado 2025 (for synthesizing and programming the FPGA)
- Arduino IDE (for uploading the LED control script)
- YOLOv8 Nano weights file (`yolov8n.pt`) in the project root

### Steps

1. **Program the FPGA**
   - Open Vivado and create a project with all files in `FPGA_files/`
   - Use `traffic_top.xdc` for pin constraints (configured for Basys 3)
   - Synthesize, implement, and generate the bitstream
   - Program the Basys 3 board

2. **Upload the Arduino sketch**
   - Open `Arduino-LED-Control_files/Arduino_control_script.c++` in the Arduino IDE
   - Wire LEDs to pins 8-13 (pins 11-13 for light 1, pins 8-10 for light 2)
   - Connect the FPGA TX pin (Pmod J1) to Arduino D2
   - Upload the sketch

3. **Set up the intersection model**
   - Place the webcam above the intersection model so it captures the full area
   - Position toy cars in the drawn lanes as desired

4. **Run the Python script**
   - Verify the correct COM port in `traffic_light_sim.py` (default is `COM5`)
   - Run: `python Computer-Vision_files/traffic_light_sim.py`
   - The YOLOv8 model will start detecting cars, counting per lane, and sending data to the FPGA
   - Press `q` in the OpenCV window to stop

### Pin Assignments (Basys 3)

| Signal | FPGA Pin | Description |
|--------|----------|-------------|
| `clk` | W5 | 100 MHz oscillator |
| `reset` | U18 | Center pushbutton (BTNC) |
| `rx_pin` | B18 | UART receive (PC to FPGA) |
| `tx_pin` | J1 | UART transmit (FPGA to Arduino) |
| `light_1[0]` | U16 | Light 1 yellow indicator |
| `light_1[1]` | E19 | Light 1 green indicator |
| `light_2[0]` | V19 | Light 2 yellow indicator |
| `light_2[1]` | W18 | Light 2 green indicator |

---

## Project Timeline

The development process is documented in detail in `PROJECT-TIMELINE.md`. In short:

1. **Physical model** - Built a cardboard 4-way intersection with lanes drawn and traffic light poles
2. **Arduino prototyping** - Got individual LEDs working, then built a fixed-cycle two-light controller as the baseline
3. **Computer vision** - Integrated YOLOv8 Nano for car detection, mapped detections to lane quadrants
4. **FSM design** - Mapped out all traffic scenarios and translated them into a Verilog finite state machine
5. **Robustness features** - Added minimum green time, maximum green time (starvation prevention), and switch thresholds
6. **UART integration** - Connected the Python script to the FPGA and the FPGA to the Arduino over serial
7. **Debugging** - Resolved UART signal alignment, COM port issues, Python loop structure, and lane pixel boundary corrections
8. **Testing and benchmarking** - Ran 11 controlled scenarios comparing the AI controller against the fixed-cycle baseline
