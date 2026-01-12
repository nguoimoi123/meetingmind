from ..models.chunk_model import Chunk
class ChunkController:
    @staticmethod
    def create_chunk(user_id, folder_id, file_id, chunk_index, text, embedding):
        if not all([user_id, folder_id, file_id, chunk_index is not None, text, embedding]):
            return {"error": "All chunk details are required"}, 400
        chunk = Chunk(
            user_id=user_id,
            folder_id=folder_id,
            file_id=file_id,
            chunk_index=chunk_index,
            text=text,
            embedding=embedding
        )
        chunk.save()
        return {"id": str(chunk.id), "chunk_index": chunk.chunk_index}, 201
