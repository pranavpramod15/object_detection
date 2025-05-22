# Traffic Chaos Detection System Documentation

## Overview

This system performs real-time vehicle tracking, turn classification (Right, Left, U-turn), and vehicle color detection using a YOLO model and OpenCV. The script processes traffic videos, tracks vehicles across frames, identifies entry and exit zones, determines the type of turn taken, detects vehicle colors, overlays analytics on the video, and saves summary statistics to a JSON file.

---

## File: `traffic_chaos_detection.py`

### Dependencies

- numpy
- opencv-python (`cv2`)
- ultralytics (YOLOv8)
- shapely
- json
- collections (defaultdict)
- vehicle_track (custom vehicle tracking logic)

---

## Key Components

### Entry and Exit Zones

Predefined polygonal zones marking where vehicles enter and exit the junction:

- `entry_zones`: `north_in`, `south_in`, `east_in`, `west_in`
- `exit_zones`: `north_out`, `south_out`, `east_out`, `west_out`

These are used to determine vehicle trajectories.

### YOLO Model

```python
model = YOLO('best.pt')
```

Loads a pretrained custom YOLO model for vehicle detection and tracking (class 0).

---

## Main Function: `run_traffic_chaos_detection(video_path, result_json_path, output_video_path)`

### Inputs:

- `video_path`: path to the input traffic video
- `result_json_path`: path to save JSON results
- `output_video_path`: path to save annotated video

### Workflow:

1. **Initialize Model and Data Structures**:

   - YOLO model
   - `vehicle_tracks`: track vehicles
   - `turn_counts`, `turns_by_time`, `entries_by_time`: turn statistics

2. **Draw Zones**:

   - Use OpenCV to draw entry and exit zones on the frame.

3. **Color Detection**:

   - Average pixel values in ROI to classify into color categories like Red, Green, Blue, Black, White, etc.

4. **Frame Processing**:

   - For each detected vehicle:

     - Track the center point
     - Detect entry and exit zones
     - Determine turn type
     - Assign bounding box color based on turn type:

       ```python
       'Right': (0, 0, 255)   # Red
       'Left':  (0, 255, 0)   # Green
       'U-turn': (0, 0, 0)    # Black
       'Straight': (255, 0, 0) # Blue
       ```

     - Detect vehicle color using ROI
     - Draw bounding boxes and info on frame

5. **Write Video Output**:

   - Save the annotated frames to `output_video_path`.

6. **JSON Summary Output**:

   - Counts of Right/Left/U-turns
   - Entry counts by timestamp
   - Turn counts by timestamp
   - Color statistics: white/black/other colors

### Output (JSON)

```json
{
  "turn_counts": {"Right": x, "Left": y, "U-turn": z},
  "total_count": total,
  "entries_by_time": {"0": n1, "1": n2, ...},
  "turns_by_time": {"0": {"Right": r1, ...}, ...},
  "white_car_count": w,
  "black_car_count": b,
  "different_other_color_car_types": c
}
```

---

## Color Detection Logic

- Based on average BGR values of bounding box ROI
- Categories: Red, Green, Blue, Black, Yellow, Orange, Brown, White, Silver, Cyan, Purple, Other

---

## Utilities

- `point_in_zone(point, zone)` – Check if a point is inside a polygon
- `find_zone(point, zone_dict)` – Identify which zone a point belongs to
- `draw_zones(frame, zones_dict, ...)` – Draw polygons for zones
- `detect_color(roi)` – Determine dominant color in region

---

## VehicleTrack (External Class)

Tracks:

- Entry/Exit zones
- Turn type
- Vehicle color
- Time of detection
- Flags to avoid double counting

---

## Usage Example

```python
run_traffic_chaos_detection(
    video_path="input.mp4",
    result_json_path="results.json",
    output_video_path="output.mp4"
)
```

---

## Notes

- Ensure `best.pt` is available in the working directory.
- Supports only one class (vehicle) detection.
- The code assumes a fixed video orientation and pre-defined zones for tracking.

---

## Future Improvements

- Expand detection to multiple classes (bikes, trucks, etc.)
- Use a smarter color classification algorithm
- Add lane-based logic to distinguish actual U-turns from left turns
- Support night mode via brightness/contrast adjustments
- Add GUI or real-time dashboard for live camera feeds

---

## Author

Developed as part of a traffic analytics system using YOLO and OpenCV.
