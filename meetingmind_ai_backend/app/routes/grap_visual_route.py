import json
from datetime import datetime

from flask import Blueprint, jsonify, request

from app.models.studio_result_model import StudioResult
from app.services.authorization_service import (
    require_folder_owner,
    require_same_user,
    require_studio_result_owner,
)
from app.services.studio_service.chunk_service import get_full_text_by_folder
from app.services.studio_service.grap_visual_service import generate_graph

grap_visual_bp = Blueprint("grap_visual", __name__, url_prefix="/grap_visual")


def _build_mindmap_result(user_id: str, folder_id: str, name: str, graph: dict):
    graph_json_str = json.dumps(graph, ensure_ascii=False)
    size_bytes = len(graph_json_str.encode("utf-8"))
    metadata = {
        "nodes_count": len(graph.get("nodes", [])),
        "edges_count": len(graph.get("edges", [])),
        "graph_data": graph,
    }

    result = StudioResult(
        user_id=user_id,
        folder_id=folder_id,
        type="mindmap",
        name=name,
        url="",
        size=size_bytes,
        metadata=metadata,
        created_at=datetime.utcnow(),
    )
    result.save()
    return result, metadata, size_bytes


@grap_visual_bp.route("/generate_visual/<folder_id>", methods=["POST"])
def generate_visual(folder_id):
    data = request.get_json() or {}
    user_id = data.get("user_id")
    name = data.get("name", "Mindmap")

    if not user_id:
        return jsonify({"error": "user_id is required"}), 400

    _, auth_error = require_same_user(request, user_id)
    if auth_error:
        return auth_error
    _, _, folder_error = require_folder_owner(request, folder_id)
    if folder_error:
        return folder_error

    full_text = get_full_text_by_folder(folder_id)
    if not full_text:
        return jsonify({"error": "No content found in the specified folder."}), 404

    graph = generate_graph(full_text)
    if not graph or not graph.get("nodes"):
        return jsonify({"error": "Failed to generate graph from text"}), 500

    try:
        result, metadata, size_bytes = _build_mindmap_result(user_id, folder_id, name, graph)
        return jsonify(
            {
                "success": True,
                "result_id": str(result.id),
                "name": name,
                "graph": graph,
                "stats": {
                    "nodes_count": metadata["nodes_count"],
                    "edges_count": metadata["edges_count"],
                    "size_bytes": size_bytes,
                },
            }
        ), 200
    except Exception as e:
        return jsonify({"success": False, "graph": graph, "error": str(e)}), 200


@grap_visual_bp.route("/get_visual/<result_id>", methods=["GET"])
def get_visual(result_id):
    _, result, auth_error = require_studio_result_owner(request, result_id)
    if auth_error:
        return auth_error

    if result.type != "mindmap":
        return jsonify({"error": "Not a mindmap result"}), 400

    graph_data = (result.metadata or {}).get("graph_data", {})
    return jsonify(
        {
            "result_id": str(result.id),
            "name": result.name,
            "folder_id": result.folder_id,
            "graph": graph_data,
            "created_at": result.created_at.isoformat(),
            "stats": {
                "nodes_count": (result.metadata or {}).get("nodes_count", 0),
                "edges_count": (result.metadata or {}).get("edges_count", 0),
                "size_bytes": result.size,
            },
        }
    ), 200


@grap_visual_bp.route("/generate_and_save/<folder_id>", methods=["POST"])
def generate_and_save_visual(folder_id):
    data = request.get_json() or {}
    user_id = data.get("user_id")
    name = data.get("name", "Mindmap")

    if not user_id:
        return jsonify({"error": "user_id is required"}), 400

    _, auth_error = require_same_user(request, user_id)
    if auth_error:
        return auth_error
    _, _, folder_error = require_folder_owner(request, folder_id)
    if folder_error:
        return folder_error

    full_text = get_full_text_by_folder(folder_id)
    if not full_text:
        return jsonify({"error": "No content found in the specified folder."}), 404

    graph = generate_graph(full_text)
    if not graph or not graph.get("nodes"):
        return jsonify({"error": "Failed to generate graph from text"}), 500

    try:
        result, metadata, size_bytes = _build_mindmap_result(user_id, folder_id, name, graph)
        return jsonify(
            {
                "success": True,
                "result_id": str(result.id),
                "graph": graph,
                "stats": {
                    "nodes_count": metadata["nodes_count"],
                    "edges_count": metadata["edges_count"],
                    "size_bytes": size_bytes,
                },
            }
        ), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
