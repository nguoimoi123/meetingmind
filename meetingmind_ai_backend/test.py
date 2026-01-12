from mongoengine import connect
import os

MONGO_URI = os.getenv(
    "MONGO_URI"
)

try:
    connect(host=MONGO_URI)
    print("✅ KẾT NỐI MONGODB THÀNH CÔNG")
except Exception as e:
    print("❌ KẾT NỐI THẤT BẠI")
    print(e)
