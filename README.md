# 🚦 Traffic Chaos Detection Bot

An AI-powered traffic analysis system that processes junction videos to detect vehicle turns (left, right, U-turn), classify their colors, and lets you interactively ask questions through a chatbot powered by a local LLM.

---

## 📸 Features

- 🎥 Upload traffic videos from your gallery
- 🧠 Detect & count:
  - Left, Right, and U-turns
  - Vehicle color classification
- 🤖 Chatbot Q&A about detected analytics using a local LLM (like LLaMA 3.2 via Ollama)
- 📊 JSON results with full vehicle metadata
- 🔁 Live video playback with detection overlay (via `video_player`)

---

## 🏗️ System Architecture

      +------------------+
      |  Flutter App     |
      |------------------|
      | - Upload video   |
      | - Play result    |
      | - Chat interface |
      +--------+---------+
               |
               ▼
    +----------+-----------+
    |      FastAPI Backend |
    |----------------------|
    | - /upload/           |
    | - /result?task_id=   |
    | - /video/<filename>  |
    | - /ask/              |
    +----------+-----------+
               |
               ▼
    +----------+-----------+
    | YOLOv8 + OpenCV +    |
    | Shapely (Turn Logic) |
    | + Color Detection    |
    +----------------------+

---

## 🧠 Local LLM Integration

- Integrates with [Ollama](https://ollama.com) (e.g., LLaMA 3.2)
- Uses `/ask/` endpoint to allow natural language queries on JSON results

---

## 🧪 Backend (FastAPI)

### Key Files

- `traffic_chaos_detection.py` – YOLO + logic for turn detection, color classification
- `vehicle_track.py` – DeepSORT and tracking logic
- `main.py` (Flask/FastAPI) – Upload, polling, serving video, chatbot API

### Endpoints

- `POST /upload/` – Accepts video file, triggers processing
- `GET /result?task_id=` – Polls for processing result
- `GET /video/<filename>` – Serves processed video
- `POST /ask/` – Accepts `{ question, result }`, returns LLM answer

---

## 📱 Frontend (Flutter)

### Key Files

- `main.dart` – Upload, video player, chat UI
- `chat_bubble.dart` – Chat UI component
- `typing_indicator.dart` – Animated typing dots
- `upload_status_indicator.dart` – Upload/progress box
- `dotted_container.dart` – Optional decorative widget

### Features

- Upload video with `image_picker`
- Poll and play video with `video_player`
- Ask questions after result is ready
- Chatbot responses appear in styled bubbles

---

## 🚀 Setup Instructions

### 1. Backend Setup (FastAPI)

> Requires Python 3.8+, virtualenv recommended

```bash
git clone https://github.com/your-username/traffic-chaos-bot.git
cd backend
pip install -r requirements.txt
uvicorn api_service:app --reload
```
