from typing import Optional

turn_map = {
    "north_in": {"east_out": "Left", "south_out": "Straight", "west_out": "Right", "north_out": "U-turn"},
    "east_in": {"south_out": "Left", "west_out": "Straight", "north_out": "Right", "east_out": "U-turn"},
    "south_in": {"west_out": "Left", "north_out": "Straight", "east_out": "Right", "south_out": "U-turn"},
    "west_in": {"north_out": "Left", "east_out": "Straight", "south_out": "Right", "west_out": "U-turn"}
}

class VehicleTrack:
    def __init__(self, track_id: int):
        self.track_id: int = track_id
        self.entered_into: Optional[str] = None
        self.exited_out: Optional[str] = None
        self.turn: Optional[str] = None
        self.turned_at: Optional[float] = None  # Time in seconds when turn was detected
        self.color: str = "Unknown"
        self.counted_entry: bool = False  # To count entry only once
        self.counted_turn: bool = False   # To count turn only once

    def set_entry(self, entry: str):
        self.entered_into = entry

    def set_exit(self, exit: str, timestamp: float):
        self.exited_out = exit
        if self.entered_into:
            self.turn = turn_map.get(self.entered_into, {}).get(self.exited_out)
            self.turned_at = timestamp
        else:
            self.turn = None
            self.turned_at = None

    def __repr__(self):
        turned_at_str = f"{self.turned_at:.2f}" if self.turned_at else "N/A"
        return (f"VehicleTrack(ID={self.track_id}, Entry={self.entered_into}, Exit={self.exited_out}, "
                f"Turn={self.turn}, TurnedAt={turned_at_str}, Color={self.color})")
