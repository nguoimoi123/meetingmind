import json
from openai import OpenAI
from app.config import Config

client = OpenAI(api_key=Config.OPENAI_API_KEY)

def summarize_transcript(transcript: str):
    prompt = f"""
Bạn là trợ lý họp.

Từ transcript sau, hãy trả về JSON gồm:
- summary
- action_items (list)
- key_decisions (list)

Transcript:
{transcript}
"""

    res = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        temperature=0.3
    )

    content = res.choices[0].message.content.strip()
    if content.startswith("```"):
        content = content.replace("```json", "").replace("```", "").strip()

    return json.loads(content)
