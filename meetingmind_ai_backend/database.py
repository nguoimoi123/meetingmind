import os
from pymongo import MongoClient
from dotenv import load_dotenv

load_dotenv()

MONGO_URI = os.getenv("MONGODB_URI")
DB_NAME = os.getenv("MONGODB_DATABASE")

client = MongoClient(MONGO_URI)
db = client[DB_NAME]

users_col = db["users"]
folders_col = db["folders"]
files_col = db["files"]
chunks_col = db["chunks"]
