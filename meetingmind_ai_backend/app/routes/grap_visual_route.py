from flask import Blueprint, request, jsonify
from app.services.studio_service.grap_visual_service import *
from app.services.studio_service.chunk_service import get_full_text_by_folder
from app.models.studio_result_model import StudioResult
from datetime import datetime
import json

grap_visual_bp = Blueprint('grap_visual', __name__, url_prefix='/grap_visual')


@grap_visual_bp.route('/generate_visual/<folder_id>', methods=['POST'])
def generate_visual(folder_id):
    data = request.get_json() or {}
    user_id = data.get('user_id')
    name = data.get('name', 'Sơ đồ tư duy')
    
    if not user_id:
        return jsonify({"error": "user_id is required"}), 400
    
    # Lấy các đoạn text từ folder
    full_text = get_full_text_by_folder(folder_id)

    if not full_text:
        return jsonify({"error": "No content found in the specified folder."}), 404
    
    print(f"📝 Processing text with {len(full_text)} characters...")
    
    # Tạo graph cho toàn bộ text
    graph = generate_graph(full_text)
    
    if not graph or not graph.get("nodes"):
        return jsonify({"error": "Failed to generate graph from text"}), 500
    
    print(f"✅ Generated graph with {len(graph['nodes'])} nodes and {len(graph['edges'])} edges.")
    
    # Lưu vào database
    try:
        print("🔄 Starting to save graph to database...")
        
        # Tính size
        graph_json_str = json.dumps(graph, ensure_ascii=False)
        size_bytes = len(graph_json_str.encode('utf-8'))
        print(f"📊 Graph size: {size_bytes} bytes")
        
        # Tạo metadata
        metadata = {
            'nodes_count': len(graph.get('nodes', [])),
            'edges_count': len(graph.get('edges', [])),
            'graph_data': graph
        }
        print(f"📝 Metadata created: {metadata['nodes_count']} nodes, {metadata['edges_count']} edges")
        
        # Lưu vào database
        print(f"💾 Creating StudioResult document...")
        result = StudioResult(
            user_id=user_id,
            folder_id=folder_id,
            type='mindmap',
            name=name,
            url='',
            size=size_bytes,
            metadata=metadata,
            created_at=datetime.utcnow()
        )
        
        print(f"💾 Saving to database...")
        result.save()
        
        print(f"✅ Saved mindmap result: {result.id}")
        
        return jsonify({
            "success": True,
            "result_id": str(result.id),
            "name": name,
            "graph": graph,
            "stats": {
                "nodes_count": metadata['nodes_count'],
                "edges_count": metadata['edges_count'],
                "size_bytes": size_bytes
            }
        }), 200
        
    except Exception as e:
        import traceback
        print(f"❌ Error saving visual graph: {e}")
        print(f"❌ Traceback: {traceback.format_exc()}")
        # Vẫn trả về graph nếu lưu thất bại
        return jsonify({
            "success": False,
            "graph": graph,
            "error": f"Graph generated but failed to save: {str(e)}",
            "stats": {
                "nodes_count": len(graph['nodes']),
                "edges_count": len(graph['edges'])
            }
        }), 200


@grap_visual_bp.route('/get_visual/<result_id>', methods=['GET'])
def get_visual(result_id):
    """Lấy lại visual graph đã lưu"""
    try:
        result = StudioResult.objects(id=result_id).first()
        
        if not result:
            return jsonify({"error": "Result not found"}), 404
        
        if result.type != 'mindmap':
            return jsonify({"error": "Not a mindmap result"}), 400
        
        graph_data = result.metadata.get('graph_data', {})
        
        return jsonify({
            "result_id": str(result.id),
            "name": result.name,
            "folder_id": result.folder_id,
            "graph": graph_data,
            "created_at": result.created_at.isoformat(),
            "stats": {
                "nodes_count": result.metadata.get('nodes_count', 0),
                "edges_count": result.metadata.get('edges_count', 0),
                "size_bytes": result.size
            }
        }), 200
        
    except Exception as e:
        print(f"❌ Error getting visual graph: {e}")
        return jsonify({"error": str(e)}), 500


@grap_visual_bp.route('/generate_and_save/<folder_id>', methods=['POST'])
def generate_and_save_visual(folder_id):
    """Tạo và lưu visual graph trong một request"""
    data = request.get_json() or {}
    user_id = data.get('user_id')
    name = data.get('name', 'Sơ đồ tư duy')
    
    if not user_id:
        return jsonify({"error": "user_id is required"}), 400
    
    # Lấy text từ folder
    full_text = get_full_text_by_folder(folder_id)
    
    if not full_text:
        return jsonify({"error": "No content found in the specified folder."}), 404
    
    print(f"📝 Processing text with {len(full_text)} characters...")
    
    # Tạo graph
    graph = generate_graph(full_text)
    
    if not graph or not graph.get("nodes"):
        return jsonify({"error": "Failed to generate graph from text"}), 500
    
    print(f"✅ Generated graph with {len(graph['nodes'])} nodes and {len(graph['edges'])} edges.")
    
    try:
        # Tính size
        graph_json_str = json.dumps(graph, ensure_ascii=False)
        size_bytes = len(graph_json_str.encode('utf-8'))
        
        # Tạo metadata
        metadata = {
            'nodes_count': len(graph.get('nodes', [])),
            'edges_count': len(graph.get('edges', [])),
            'graph_data': graph
        }
        
        # Lưu vào database
        result = StudioResult(
            user_id=user_id,
            folder_id=folder_id,
            type='mindmap',
            name=name,
            url='',
            size=size_bytes,
            metadata=metadata,
            created_at=datetime.utcnow()
        )
        result.save()
        
        print(f"✅ Saved mindmap result: {result.id}")
        
        return jsonify({
            "success": True,
            "result_id": str(result.id),
            "graph": graph,
            "stats": {
                "nodes_count": metadata['nodes_count'],
                "edges_count": metadata['edges_count'],
                "size_bytes": size_bytes
            }
        }), 200
        
    except Exception as e:
        print(f"❌ Error saving visual graph: {e}")
        return jsonify({"error": str(e)}), 500
