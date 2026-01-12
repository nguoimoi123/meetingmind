from database import users_col
from models.user_model import user_schema_google

user = user_schema_google(
    "test@gmail.com",
    "Test User",
    "https://avatar.com"
)

users_col.insert_one(user)
print("Inserted user")
