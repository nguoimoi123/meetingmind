from flask import Blueprint, request, jsonify
from app.services.studio_service.chunk_service import get_full_text_by_folder
from app.services.studio_service.gpt_service import generate_conversation
from app.services.studio_service.tts_service import text_to_speech
from app.services.studio_service.cloudinary_service import upload_audio
from app.services.studio_result_service import StudioResultController
from app.services.authorization_service import require_folder_owner, require_same_user

tts_studio_bp = Blueprint('tts_studio', __name__, url_prefix='/tts_studio')

@tts_studio_bp.route('/generate_audio/<folder_id>', methods=['POST'])
def generate_audio(folder_id):
    data = request.get_json() or {}
    user_id = data.get('user_id')
    
    if not user_id:
        return jsonify({"error": "user_id is required"}), 400

    _, auth_error = require_same_user(request, user_id)
    if auth_error:
        return auth_error
    _, _, folder_error = require_folder_owner(request, folder_id)
    if folder_error:
        return folder_error
    
    # Lấy full text
    full_text = get_full_text_by_folder(folder_id)

    if not full_text:
        return jsonify({"error": "No content found in the specified folder."}), 404
    
    # GPT
    conversation = generate_conversation(full_text)

    # TTS
    audio_content = text_to_speech(conversation)

    # Upload lên Cloudinary
    audio_url = upload_audio(audio_content)
    
    # Lưu vào database
    result, status_code = StudioResultController.create_result(
        user_id=user_id,
        folder_id=folder_id,
        result_type='audio_summary',
        name='Tóm tắt âm thanh.mp3',
        url=audio_url,
        metadata={'conversation': conversation}
    )
    
    if status_code != 201:
        return jsonify(result), status_code
    
    return jsonify({
        "audio_url": audio_url,
        "conversation": conversation,
        "result_id": result.get('id')
    }), 200
