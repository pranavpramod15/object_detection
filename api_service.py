import uuid
import shutil
import json
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
from fastapi import FastAPI, UploadFile, File, Query
from fastapi.responses import JSONResponse, FileResponse

app = FastAPI()

BASE_DIR = Path(__file__).resolve().parent
UPLOAD_DIR = BASE_DIR / "uploads"
RESULT_DIR = BASE_DIR / "results"
UPLOAD_DIR.mkdir(exist_ok=True)
RESULT_DIR.mkdir(exist_ok=True)

progress_store = {}
result_store = {}

executor = ThreadPoolExecutor(max_workers=2)


def process_video(task_id: str, video_path: Path):
    from traffic_chaos_detection import run_traffic_chaos_detection

    # Output paths for video and JSON
    output_video_path = RESULT_DIR / f"{task_id}_annotated.mp4"
    result_json_path = RESULT_DIR / f"{task_id}_analytics.json"

    # Run detection
    analytics = run_traffic_chaos_detection(str(video_path), str(result_json_path), str(output_video_path))

    # Save in-memory result info
    result_store[task_id] = {
        "filename": output_video_path.name,
        "analytics": analytics
    }

    # Mark progress done
    progress_store[task_id] = 100


@app.post("/upload")
@app.post("/upload/")
async def upload_video(file: UploadFile = File(...)):
    task_id = str(uuid.uuid4())
    filename = UPLOAD_DIR / f"{task_id}_{file.filename}"

    with open(filename, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    progress_store[task_id] = 0
    executor.submit(process_video, task_id, filename)

    return {"task_id": task_id}


@app.get("/progress")
def get_progress(task_id: str = Query(...)):
    if task_id in progress_store:
        return {"task_id": task_id, "progress": progress_store[task_id]}
    return JSONResponse(status_code=404, content={"error": "Invalid task_id"})


@app.get("/video/{filename}")
def get_video(filename: str):
    file_path = RESULT_DIR / filename
    if file_path.exists():
        return FileResponse(path=file_path, media_type='video/mp4', filename=filename)
    return JSONResponse(status_code=404, content={"error": "Video not found"})


@app.get("/result")
def get_result(task_id: str = Query(...)):
    result = result_store.get(task_id)
    if result:
        return {
            "task_id": task_id,
            "filename": result["filename"],
            "analytics": result["analytics"]
        }
    return JSONResponse(status_code=404, content={"error": "Result not ready"})

@app.post("/ask")
@app.post("/ask/")
async def ask_bot(payload: dict):
    question = payload["question"]
    result = payload["result"]
    print("Received result:", result)
    print("Received Question:", question)
    # Extract and format data
    turn_counts = result.get("turn_counts", {})
    total_count = result.get("total_count", "unknown")
    white = result.get("white_car_count", "unknown")
    black = result.get("black_car_count", "unknown")
    other_colors = result.get("different_other_color_car_types", "unknown")

    context = f"""
Traffic Analytics Summary:

- Total Cars: {total_count}
- Turn Counts:
    • Left: {turn_counts.get("Left", 0)}
    • Right: {turn_counts.get("Right", 0)}
    • U-turns: {turn_counts.get("U-turn", 0)}
- Vehicle Colors:
    • White: {white}
    • Black: {black}
    • Other Colors: {other_colors}

Question: {question}
""".strip()

    import requests
    response = requests.post(
        "http://localhost:11434/api/generate",
        json={
            "model": "llama3.2",
            "prompt": context,
            "stream": False
        }
    )

    try:
        response_json = response.json()
        answer = response_json.get("response", "No answer received.")
    except Exception as e:
        return JSONResponse(status_code=500, content={"error": f"Failed to parse response: {str(e)}"})

    return {"answer": answer}
