import asyncio, queue, threading
from flask import request
from flask_socketio import emit
from app.extensions import socketio
from app.services.speechmatics_service import sm_worker
from app.services.meeting_service import get_or_create_meeting

# Dictionary lưu queue cho từng sid active (chỉ dùng để worker lấy data audio)
audio_queues = {}

@socketio.on("start_streaming")
def start_streaming():
    sid = request.sid
    
    # Lấy user_id từ query params trong socket connect hoặc mặc định
    user_id = request.args.get('user_id', 'default_user')
    
    # 1. Tạo/Cập nhật record Meeting trong DB
    get_or_create_meeting(sid, user_id)
    
    # 2. Tạo queue cho sid này
    audio_queues[sid] = queue.Queue()

    loop = asyncio.new_event_loop()

    def runner():
        asyncio.set_event_loop(loop)
        loop.run_until_complete(sm_worker(sid, audio_queues[sid]))
        loop.close()

    threading.Thread(target=runner, daemon=True).start()
    emit("status", {"msg": "Speechmatics ready"})

@socketio.on("audio_data")
def audio_data(data):
    sid = request.sid
    if sid in audio_queues and len(data) > 5:
        audio_queues[sid].put(data[5:])

@socketio.on("end_meeting")
def end_meeting():
    sid = request.sid
    if sid in audio_queues:
        audio_queues[sid].put(None)

@socketio.on("disconnect")
def disconnect():
    audio_queues.pop(request.sid, None)