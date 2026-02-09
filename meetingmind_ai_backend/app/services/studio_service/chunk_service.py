from app.models.chunk_model import Chunk

def get_full_text_by_folder(folder_id):
    chunks = Chunk.objects(folder_id=folder_id).order_by('chunk_index')
    
    if not chunks:
        return ""
    
    # Chunk đầu tiên: lấy full text
    full_text = chunks[0].text
    
    # Các chunk tiếp theo: bỏ 100 ký tự overlap rồi nối vào
    for chunk in chunks[1:]:
        full_text += chunk.text[100:]
    
    return full_text


