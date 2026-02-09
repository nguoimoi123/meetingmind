from openai import OpenAI
import os
from dotenv import load_dotenv
import json
load_dotenv()
client = OpenAI(
    api_key=os.getenv("OPENAI_API_KEY")
)

def generate_graph(text):
    prompt = f"""
Bạn là chuyên gia phân tích và trực quan hóa kiến thức. Nhiệm vụ của bạn là tạo một sơ đồ tư duy (mind map) dưới dạng đồ thị kiến thức từ văn bản được cung cấp.

HƯỚNG DẪN CHI TIẾT:
1. Đọc kỹ văn bản và xác định các khái niệm chính, phụ và chi tiết
2. Tạo các NÚT (nodes) đại diện cho:
   - Chủ đề chính (1 nút trung tâm)
   - Các khái niệm quan trọng (nút cấp 1)
   - Các chi tiết và ví dụ (nút cấp 2, 3)
3. Tạo các MỐI QUAN HỆ (edges) thể hiện liên kết logic giữa các khái niệm

CẤU TRÚC JSON CHUẨN:
{{{{
  "nodes": [
    {{{{"id": "tên_khái_niệm", "label": "Nhãn hiển thị", "level": 0, "type": "main"}}}},
    {{{{"id": "khái_niệm_con", "label": "Nhãn con", "level": 1, "type": "subtopic"}}}}
  ],
  "edges": [
    {{{{"from": "nút_gốc", "to": "nút_đích", "relation": "loại_quan_hệ"}}}}
  ]
}}}}

CÁC LOẠI QUAN HỆ (relation) CÓ THỂ DÙNG:
- "chủ_đề_chính": Từ nút trung tâm đến các khái niệm chính
- "chi_tiết": Từ khái niệm chính đến các chi tiết cụ thể
- "bao_gồm": A bao gồm B (phần tử)
- "dẫn_đến": A gây ra hoặc dẫn đến B
- "liên_quan": Hai khái niệm có liên hệ với nhau
- "ví_dụ": Đưa ra ví dụ minh họa
- "phương_pháp": Cách thức thực hiện
- "đối_lập": Hai khái niệm trái ngược
- "so_sánh": So sánh giữa hai khái niệm
- "kết_quả": Hậu quả hoặc kết quả của một hành động

CÁC CẤP ĐỘ NÚT (level):
- 0: Nút trung tâm (chủ đề chính)
- 1: Khái niệm chính
- 2: Chi tiết, ví dụ
- 3: Thông tin bổ sung

YÊU CẦU:
✓ Trích xuất TỐI THIỂU 8-15 nút (nodes) để đảm bảo đồ thị đầy đủ
✓ Mỗi nút phải có id, label, level và type
✓ Tạo mối quan hệ logic và rõ ràng giữa các nút
✓ Ưu tiên các khái niệm quan trọng, loại bỏ thông tin không cần thiết
✓ Sử dụng tiếng Việt có dấu cho tất cả nhãn (label)
✓ CHỈ TRẢ VỀ JSON, KHÔNG CÓ MARKDOWN, GIẢI THÍCH HAY VĂN BẢN NÀO KHÁC

VĂN BẢN CẦN PHÂN TÍCH:
{text}
"""

    try:
        # Gọi OpenAI API với định dạng ĐÚNG
        response = client.chat.completions.create(
            model="gpt-4o-mini",  # Model tồn tại
            messages=[
                {"role": "system", "content": "Bạn là chuyên gia phân tích và trực quan hóa kiến thức. Chỉ trả về JSON thuần, không có markdown hay giải thích."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.7,
            response_format={"type": "json_object"}  # Bắt buộc trả về JSON
        )

        # Lấy nội dung response ĐÚNG CÁCH
        content = response.choices[0].message.content.strip()
        
        # Parse JSON
        graph_data = json.loads(content)
        
        # Validate cấu trúc
        if "nodes" not in graph_data or "edges" not in graph_data:
            raise ValueError("Missing 'nodes' or 'edges' in response")
        
        return graph_data
        
    except json.JSONDecodeError as e:
        print(f"❌ JSON decode error: {e}")
        print(f"Response content: {content}")
        # Trả về cấu trúc mặc định nếu lỗi
        return {"nodes": [], "edges": []}
    except Exception as e:
        print(f"❌ Error generating graph: {e}")
        return {"nodes": [], "edges": []}

def merge_graphs(graphs):
    nodes = {}
    edges = []

    for g in graphs:
        for node in g["nodes"]:
            nodes[node["id"]] = node

        edges.extend(g["edges"])

    return {
        "nodes": list(nodes.values()),
        "edges": edges
    }