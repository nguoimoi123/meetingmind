from flask import Blueprint, jsonify, request

from ..services.authorization_service import (
    require_folder_owner,
    require_same_user,
    require_studio_result_owner,
)
from ..services.studio_result_service import StudioResultController

studio_result_bp = Blueprint("studio_result", __name__, url_prefix="/studio_result")


@studio_result_bp.route("/create", methods=["POST"])
def create_result():
    data = request.get_json() or {}

    user_id = data.get("user_id")
    folder_id = data.get("folder_id")
    result_type = data.get("type")
    name = data.get("name")
    url = data.get("url")
    thumbnail_url = data.get("thumbnail_url")
    size = data.get("size")
    metadata = data.get("metadata")

    if not all([user_id, folder_id, result_type, name, url]):
        return jsonify({"error": "Missing required fields"}), 400

    _, auth_error = require_same_user(request, user_id)
    if auth_error:
        return auth_error
    _, _, folder_error = require_folder_owner(request, folder_id)
    if folder_error:
        return folder_error

    result, status_code = StudioResultController.create_result(
        user_id=user_id,
        folder_id=folder_id,
        result_type=result_type,
        name=name,
        url=url,
        thumbnail_url=thumbnail_url,
        size=size,
        metadata=metadata,
    )
    return jsonify(result), status_code


@studio_result_bp.route("/folder/<folder_id>", methods=["GET"])
def get_results_by_folder(folder_id):
    _, _, auth_error = require_folder_owner(request, folder_id)
    if auth_error:
        return auth_error

    result, status_code = StudioResultController.get_results_by_folder(folder_id)
    return jsonify(result), status_code


@studio_result_bp.route("/user/<user_id>", methods=["GET"])
def get_results_by_user(user_id):
    _, auth_error = require_same_user(request, user_id)
    if auth_error:
        return auth_error

    result, status_code = StudioResultController.get_results_by_user(user_id)
    return jsonify(result), status_code


@studio_result_bp.route("/<result_id>", methods=["GET"])
def get_result_by_id(result_id):
    _, _, auth_error = require_studio_result_owner(request, result_id)
    if auth_error:
        return auth_error

    result, status_code = StudioResultController.get_result_by_id(result_id)
    return jsonify(result), status_code


@studio_result_bp.route("/delete/<result_id>", methods=["DELETE"])
def delete_result(result_id):
    _, _, auth_error = require_studio_result_owner(request, result_id)
    if auth_error:
        return auth_error

    result, status_code = StudioResultController.delete_result(result_id)
    return jsonify(result), status_code
