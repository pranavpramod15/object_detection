# traffic_chaos_detection.py
import numpy as np
import cv2
from ultralytics import YOLO
from vehicle_track import VehicleTrack
from shapely.geometry import Point, Polygon
import json
from collections import defaultdict

entry_zones = {
    "north_in": [[768.82, 333.13], [815.88, 368.43], [994.31, 137.05], [927.64, 115.49]],
    "south_in": [[982.54, 988.03], [1208.03, 737.05], [1245.29, 784.11], [1059.01, 1003.72]],
    "east_in":  [[1231.56, 348.82], [1270.78, 309.60], [1482.54, 491.96], [1470.78, 550.78]],
    "west_in":  [[796.27, 793.92], [560.98, 650.78], [547.25, 709.60], [747.25, 833.13]]
}

exit_zones = {
    "north_out": [[562.94, 621.37], [796.27, 388.03], [749.21, 352.74], [555.09, 552.74]],
    "south_out": [[1229.60, 717.45], [1472.74, 531.17], [1484.50, 615.49], [1280.58, 758.62]],
    "east_out":  [[1204.11, 323.33], [1006.07, 140.98], [1076.66, 117.45], [1239.41, 286.07]],
    "west_out":  [[774.70, 839.01], [811.96, 803.72], [1008.03, 995.88], [919.80, 997.84]]
}

def run_traffic_chaos_detection(video_path: str, result_json_path: str, output_video_path: str):
    model = YOLO('best.pt')
    vehicle_tracks = {}
    turn_counts = {'Right': 0, 'Left': 0, 'U-turn': 0}
    turns_by_time = defaultdict(lambda: {'Right': 0, 'Left': 0, 'U-turn': 0})
    entries_by_time = defaultdict(int)

    turning_bb_color = {
        'Right': (0, 0, 255),
        'Left': (0, 255, 0),
        'U-turn': (0, 0, 0),
        'Straight':(255, 0, 0)
    }

    def point_in_zone(point, zone):
        return Polygon(zone).contains(Point(point))

    def find_zone(point, zone_dict):
        for name, polygon in zone_dict.items():
            if point_in_zone(point, polygon):
                return name
        return None

    def draw_zones(frame, zones_dict, color=(255, 255, 0), thickness=2, fill=False, alpha=0.3):
        overlay = frame.copy()
        for points in zones_dict.values():
            pts = np.array(points, dtype=np.int32).reshape((-1, 1, 2))
            if fill:
                cv2.fillPoly(overlay, [pts], color)
            else:
                cv2.polylines(overlay, [pts], isClosed=True, color=color, thickness=thickness)
        if fill:
            cv2.addWeighted(overlay, alpha, frame, 1 - alpha, 0, frame)
        return frame

    def detect_color(roi):
        if roi.size == 0:
            return "Unknown"
        avg_color = roi.mean(axis=0).mean(axis=0)
        b, g, r = avg_color
        if r > 150 and g < 100 and b < 100:
            return "Red"
        elif g > 150 and r < 100 and b < 100:
            return "Green"
        elif b > 150 and r < 100 and g < 100:
            return "Blue"
        elif r < 80 and g < 80 and b < 80:
            return "Black"
        elif r > 180 and g > 180 and b < 100:
            return "Yellow"
        elif r > 180 and g > 100 and b < 80:
            return "Orange"
        elif r > 100 and g < 80 and b < 50:
            return "Brown"
        elif abs(r - g) < 15 and abs(g - b) < 15 and 100 < r < 200:
            return "White"
        elif abs(r - g) < 20 and abs(g - b) < 20 and r > 200:
            return "Silver"
        elif g > 180 and b > 180 and r < 100:
            return "Cyan"
        elif r > 130 and b > 130 and g < 100:
            return "Purple"
        else:
            return "Other"

    def process_frame(frame, current_time_sec):
        results = model.track(frame, persist=True, classes=[0])[0]
        current_sec = int(current_time_sec)

        for box in results.boxes:
            if box.id is None:
                continue
            track_id = int(box.id.item())
            if track_id not in vehicle_tracks:
                vehicle_tracks[track_id] = VehicleTrack(track_id)

            vehicle = vehicle_tracks[track_id]
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            cx, cy = (x1 + x2) // 2, (y1 + y2) // 2
            center_point = (cx, cy)

            if not vehicle.entered_into:
                entry_zone = find_zone(center_point, entry_zones)
                if entry_zone:
                    vehicle.set_entry(entry_zone)
                    if not vehicle.counted_entry:
                        entries_by_time[current_sec] += 1
                        vehicle.counted_entry = True

            if vehicle.entered_into and not vehicle.exited_out:
                exit_zone = find_zone(center_point, exit_zones)
                if exit_zone:
                    vehicle.set_exit(exit_zone, current_time_sec)
                    if vehicle.turn and not vehicle.counted_turn:
                        if vehicle.turn in turn_counts:
                            turn_counts[vehicle.turn] += 1
                            turns_by_time[current_sec][vehicle.turn] += 1
                            vehicle.counted_turn = True

            roi = frame[y1:y2, x1:x2]
            vehicle.color = detect_color(roi)

            bb_color = turning_bb_color.get(vehicle.turn, (203, 192, 255))
            cv2.rectangle(frame, (x1, y1), (x2, y2),bb_color, 2)
            cv2.putText(frame, f"ID {track_id} | {vehicle.color}", (x1, y1 - 10),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.5, bb_color, 2)

        cv2.putText(frame, f"Right Turns: {turn_counts['Right']}", (30, 30),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, turning_bb_color['Right'], 2)
        cv2.putText(frame, f"Left Turns: {turn_counts['Left']}", (30, 60),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, turning_bb_color['Left'], 2)
        cv2.putText(frame, f"U-Turns: {turn_counts['U-turn']}", (30, 90),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, turning_bb_color['U-turn'], 2)

        draw_zones(frame, entry_zones, color=(0, 255, 0), fill=True, alpha=0.2)
        draw_zones(frame, exit_zones, color=(0, 0, 255), fill=True, alpha=0.2)

        return frame

    cap = cv2.VideoCapture(video_path)
    fps = cap.get(cv2.CAP_PROP_FPS)
    output = cv2.VideoWriter(output_video_path,
                             cv2.VideoWriter_fourcc(*'avc1'),
                             fps,
                             (int(cap.get(3)), int(cap.get(4))))

    while True:
        ret, frame = cap.read()
        if not ret:
            break
        current_frame_num = cap.get(cv2.CAP_PROP_POS_FRAMES)
        current_time_sec = current_frame_num / fps
        frame = process_frame(frame, current_time_sec)
        output.write(frame)

    cap.release()
    output.release()
    cv2.destroyAllWindows()

    color_frequencies = defaultdict(int)
    for track in vehicle_tracks.values():
        color_frequencies[track.color] += 1

    result_data = {
        "turn_counts": turn_counts,
        "total_count": sum(entries_by_time.values()) + sum(sum(t.values()) for t in turns_by_time.values()),
        "entries_by_time": dict(entries_by_time),
        "turns_by_time": dict(turns_by_time),
        "white_car_count": color_frequencies.get("White", 0),
        "black_car_count": color_frequencies.get("Black", 0),
        "different_other_color_car_types": len({k for k in color_frequencies if k not in ["White", "Black"]})
    }

    with open(result_json_path, "w") as f:
        json.dump(result_data, f, indent=4)

    return result_data
