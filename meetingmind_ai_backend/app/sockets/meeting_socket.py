import asyncio, queue, threading
from flask import request
from flask_socketio import emit
from app.extensions import socketio
from app.services.speechmatics_service import sm_worker, sessions, session_transcripts

@socketio.on("start_streaming")
def start_streaming():
    sid = request.sid
    sessions[sid] = queue.Queue()
    session_transcripts[sid] = []

    loop = asyncio.new_event_loop()

    def runner():
        asyncio.set_event_loop(loop)
        loop.run_until_complete(sm_worker(sid, sessions[sid]))
        loop.close()

    threading.Thread(target=runner, daemon=True).start()
    emit("status", {"msg": "Speechmatics ready"})

@socketio.on("audio_data")
def audio_data(data):
    sid = request.sid
    if sid in sessions and len(data) > 5:
        sessions[sid].put(data[5:])

@socketio.on("end_meeting")
def end_meeting():
    sid = request.sid
    if sid in sessions:
        sessions[sid].put(None)

@socketio.on("disconnect")
def disconnect():
    sessions.pop(request.sid, None)
