import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    SECRET_KEY = os.getenv("SECRET_KEY")
    MONGODB_SETTINGS = {
        "db": os.getenv("MONGO_DB"),
        "host": os.getenv("MONGO_URI")
    }
    SECRET_KEY = os.getenv("SECRET_KEY")
    SPEECHMATICS_API_KEY = os.getenv("SPEECHMATICS_API_KEY")
    OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
    SM_URL = "wss://eu.rt.speechmatics.com/v2"
    HEADER_LEN = 5

    CLOUD_NAME = os.getenv("CLOUD_NAME")
    API_KEY = os.getenv("API_KEY")
    API_SECRET = os.getenv("API_SECRET")
    ADMIN_DASHBOARD_KEY = os.getenv("ADMIN_DASHBOARD_KEY") or SECRET_KEY
    PAYMENT_WEBHOOK_SECRET = os.getenv("PAYMENT_WEBHOOK_SECRET")
    VNPAY_TMN_CODE = os.getenv("VNPAY_TMN_CODE")
    VNPAY_HASH_SECRET = os.getenv("VNPAY_HASH_SECRET")
    VNPAY_PAYMENT_URL = (
        os.getenv("VNPAY_PAYMENT_URL")
        or "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html"
    )
    VNPAY_RETURN_URL = os.getenv("VNPAY_RETURN_URL")
    VNPAY_IPN_URL = os.getenv("VNPAY_IPN_URL")
    VNPAY_LOCALE = os.getenv("VNPAY_LOCALE") or "vn"
