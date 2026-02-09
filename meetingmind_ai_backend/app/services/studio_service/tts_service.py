from openai import OpenAI
import os
import json
import subprocess
from dotenv import load_dotenv

load_dotenv()
client = OpenAI(
    api_key=os.getenv("OPENAI_API_KEY")
)

def parse_conversation(json_text):
    """Phân tích conversation JSON thành các đoạn theo người nói"""
    try:
        data = json.loads(json_text)
        conversation = data.get('conversation', [])
        
        segments = []
        for item in conversation:
            speaker = item.get('speaker', '').strip()
            text = item.get('text', '').strip()
            
            if text:  # Chỉ thêm nếu có nội dung
                segments.append({
                    'speaker': speaker,
                    'text': text
                })
        
        return segments
    except json.JSONDecodeError:
        return []

def create_audio_segment(text, voice, index):
    """Tạo audio segment cho một đoạn text với giọng nói cụ thể"""
    temp_file = f"temp_{index}_{voice}.mp3"
    
    with client.audio.speech.with_streaming_response.create(
        model="gpt-4o-mini-tts",
        voice=voice,
        input=text
    ) as response:
        response.stream_to_file(temp_file)
    
    return temp_file

def text_to_speech(json_text):
    """
    Chuyển đổi conversation JSON thành audio với nhiều giọng nói
    - teacher (Giáo viên): giọng echo (nam, trầm)
    - student (Học sinh): giọng nova (nữ, trẻ)
    """
    speech_file = "output.mp3"
    
    # Parse conversation JSON thành các segments
    segments = parse_conversation(json_text)
    
    if not segments:
        # Nếu không parse được, dùng giọng mặc định cho toàn bộ
        with client.audio.speech.with_streaming_response.create(
            model="gpt-4o-mini-tts",
            voice="alloy",
            input=json_text
        ) as response:
            response.stream_to_file(speech_file)
        return speech_file
    
    # Tạo audio cho từng segment
    temp_files = []
    
    for i, segment in enumerate(segments):
        # Chọn giọng nói phù hợp
        if segment['speaker'] == 'teacher':
            voice = 'echo'  # Giọng nam, trầm cho giáo viên
        else:  # student
            voice = 'nova'  # Giọng nữ, trẻ cho học sinh
        
        # Tạo audio segment
        temp_file = create_audio_segment(segment['text'], voice, i)
        temp_files.append(temp_file)
    
    # Ghép các file audio bằng ffmpeg
    try:
        # Tạo file list cho ffmpeg
        list_file = "filelist.txt"
        with open(list_file, 'w') as f:
            for temp_file in temp_files:
                f.write(f"file '{temp_file}'\n")
        
        # Sử dụng ffmpeg để ghép các file với re-encode để tránh lỗi
        subprocess.run([
            'ffmpeg', '-f', 'concat', '-safe', '0',
            '-i', list_file,
            '-acodec', 'libmp3lame',  # Re-encode để đảm bảo tương thích
            '-ab', '128k',  # Bitrate 128kbps
            '-y',  # Overwrite output file
            speech_file
        ], check=True, capture_output=True)
        
        # Xóa file list
        if os.path.exists(list_file):
            os.remove(list_file)
            
    except subprocess.CalledProcessError as e:
        # Nếu ffmpeg không có hoặc lỗi, nối binary đơn giản
        print(f"FFmpeg error: {e}, using simple concatenation")
        with open(speech_file, 'wb') as outfile:
            for temp_file in temp_files:
                with open(temp_file, 'rb') as infile:
                    outfile.write(infile.read())
    except FileNotFoundError:
        # Nếu không tìm thấy ffmpeg, nối binary đơn giản
        print("FFmpeg not found, using simple concatenation")
        with open(speech_file, 'wb') as outfile:
            for temp_file in temp_files:
                with open(temp_file, 'rb') as infile:
                    outfile.write(infile.read())
    
    # Xóa các file tạm
    for temp_file in temp_files:
        if os.path.exists(temp_file):
            os.remove(temp_file)
    
    return speech_file