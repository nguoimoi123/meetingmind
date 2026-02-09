from openai import OpenAI
import os
from dotenv import load_dotenv

load_dotenv()
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

def generate_conversation(text):
    """Tạo cuộc hội thoại từ văn bản"""
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        response_format={"type": "json_object"},
        messages=[
            {
                "role": "system",
                "content": """Bạn là trợ lý chuyển văn bản thành cuộc hội thoại học tập.
Luôn trả về JSON với format:
{
  "conversation": [
    {"speaker": "student", "text": "..."},
    {"speaker": "teacher", "text": "..."}
  ]
}"""
            },
            {
                "role": "user",
                "content": f"""Biến nội dung sau thành cuộc hội thoại tự nhiên giữa học sinh và giáo viên AI.

YÊU CẦU:
1. Học sinh chủ động hỏi những câu hỏi nhỏ, cụ thể
2. Giáo viên trả lời ngắn gọn, dễ hiểu
3. Tạo cuộc trò chuyện qua lại liên tục, mỗi lượt ngắn
4. Học sinh tổng kết ở cuối

Format JSON:
{{
  "conversation": [
    {{"speaker": "student", "text": "..."}},
    {{"speaker": "teacher", "text": "..."}}
  ]
}}

Nội dung:
{text}"""
            }
        ]
    )

    return response.choices[0].message.content
