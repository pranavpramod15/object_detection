# Traffic Video Analytics API Documentation

This document provides a detailed overview of the FastAPI backend responsible for handling traffic video uploads, processing them for turn and color analytics using YOLO-based detection, and interacting with an LLM for answering analytics-based queries.

---

## Endpoints Overview

### 1. **`POST /upload`**

**Description**: Upload a video for processing.

**Request**:

- **file**: A video file to upload (form-data).

**Response**:

```json
{
  "task_id": "<uuid>"
}
```

**Behavior**:

- Stores the uploaded video in `uploads/`.
- Initiates background processing using `traffic_chaos_detection.py`.
- Processing runs in a separate thread.

---

### 2. **`GET /progress?task_id=...`**

**Description**: Check progress of the video processing.

**Response**:

```json
{
  "task_id": "<uuid>",
  "progress": 0 to 100
}
```

**Errors**:

- `404`: Invalid task ID.

---

### 3. **`GET /video/{filename}`**

**Description**: Download the processed annotated video.

**Response**:

- `200`: Returns MP4 file.
- `404`: If the file does not exist.

---

### 4. **`GET /result?task_id=...`**

**Description**: Retrieve the JSON analytics result for the uploaded video.

**Response**:

```json
{
  "task_id": "<uuid>",
  "filename": "<annotated_video_filename>",
  "analytics": {
    "turn_counts": {"Right": int, "Left": int, "U-turn": int},
    "total_count": int,
    "entries_by_time": {"sec": count},
    "turns_by_time": {"sec": {"Right": int, ...}},
    "white_car_count": int,
    "black_car_count": int,
    "different_other_color_car_types": int
  }
}
```

**Errors**:

- `404`: If result is not yet ready.

---

### 5. **`POST /ask`**

**Description**: Ask a question about the result using an LLM.

**Request**:

```json
{
  "question": "How many white cars?",
  "result": { ... } // output from /result
}
```

**Response**:

```json
{
  "answer": "The number of white cars detected was 14."
}
```

**Errors**:

- `500`: If the LLM call fails or response can't be parsed.

**LLM Configuration**:

- Calls local Ollama LLM server (`localhost:11434`) using `llama3.2`.
- Prepares context from analytics JSON and appends the user’s question.

---

## Internal Components

### Directories

- `uploads/`: Stores incoming video files.
- `results/`: Stores processed video and JSON results.

### State Stores

- `progress_store`: Tracks video processing progress by `task_id`.
- `result_store`: Caches result metadata in-memory for fast retrieval.

---

## Processing Pipeline

- Each uploaded video is processed by `run_traffic_chaos_detection()` which:

  - Detects vehicles and their turns (Left, Right, U-turn).
  - Classifies vehicle color.
  - Outputs:

    - Annotated MP4 video
    - JSON file with summarized analytics

---

## Enhancement Suggestions

- Add user authentication.
- Store results persistently (e.g., database).
- Allow partial downloads or streamed playback.
- Expand `/ask` with more advanced prompt engineering or multi-turn chat.

---

For integration or development questions, please reach out to the maintainer.
