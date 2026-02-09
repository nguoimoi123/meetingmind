from flask import Blueprint, request, jsonify
from ..services.studio_result_service import StudioResultController

studio_result_bp = Blueprint('studio_result', __name__, url_prefix='/studio_result')

@studio_result_bp.route('/create', methods=['POST'])
def create_result():
    """Tạo studio result mới"""
    data = request.get_json()
    
    user_id = data.get('user_id')
    folder_id = data.get('folder_id')
    result_type = data.get('type')
    name = data.get('name')
    url = data.get('url')
    thumbnail_url = data.get('thumbnail_url')
    size = data.get('size')
    metadata = data.get('metadata')
    
    if not all([user_id, folder_id, result_type, name, url]):
        return jsonify({"error": "Missing required fields"}), 400
    
    result, status_code = StudioResultController.create_result(
        user_id=user_id,
        folder_id=folder_id,
        result_type=result_type,
        name=name,
        url=url,
        thumbnail_url=thumbnail_url,
        size=size,
        metadata=metadata
    )
    
    return jsonify(result), status_code

@studio_result_bp.route('/folder/<folder_id>', methods=['GET'])
def get_results_by_folder(folder_id):
    """Lấy tất cả studio results của một folder"""
    result, status_code = StudioResultController.get_results_by_folder(folder_id)
    return jsonify(result), status_code

@studio_result_bp.route('/user/<user_id>', methods=['GET'])
def get_results_by_user(user_id):
    """Lấy tất cả studio results của một user"""
    result, status_code = StudioResultController.get_results_by_user(user_id)
    return jsonify(result), status_code

@studio_result_bp.route('/<result_id>', methods=['GET'])
def get_result_by_id(result_id):
    """Lấy một studio result theo ID"""
    result, status_code = StudioResultController.get_result_by_id(result_id)
    return jsonify(result), status_code

@studio_result_bp.route('/delete/<result_id>', methods=['DELETE'])
def delete_result(result_id):
    """Xóa studio result"""
    result, status_code = StudioResultController.delete_result(result_id)
    return jsonify(result), status_code
