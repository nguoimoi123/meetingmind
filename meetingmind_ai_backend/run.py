import os


if not os.getenv("SOCKETIO_ASYNC_MODE") and os.getenv("RENDER"):
    os.environ["SOCKETIO_ASYNC_MODE"] = "eventlet"

if os.getenv("SOCKETIO_ASYNC_MODE") == "eventlet":
    import eventlet

    eventlet.monkey_patch()

from app import create_app
from app.extensions import socketio

app = create_app()

if __name__ == "__main__":
    port = int(os.getenv("PORT", "5000"))
    debug = os.getenv("FLASK_DEBUG", "").lower() in {"1", "true", "yes"}

    socketio.run(
        app,
        host="0.0.0.0",
        port=port,
        debug=debug,
        use_reloader=False,
        allow_unsafe_werkzeug=not debug,
    )
