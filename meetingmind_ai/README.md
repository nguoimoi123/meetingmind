# MeetingMind AI

MeetingMind AI là trợ lý cuộc họp thông minh: ghi âm, chép lời realtime, tóm tắt, tạo action items, quản lý notebook và cộng tác nhóm.

## Tính năng chính

- Đăng nhập Google/Email, lưu phiên người dùng.
- Ghi âm và chép lời realtime qua Socket.IO + Speechmatics.
- Tóm tắt cuộc họp bằng AI (summary, action items, key decisions).
- RAG/Chat với nội dung cuộc họp và notebook.
- Quản lý notebook và file tri thức.
- Lịch và nhắc việc (reminders) theo ngày.
- Teams: mời thành viên, sự kiện nhóm.
- Tìm kiếm toàn hệ thống.
- Thông báo local + deep-link.

## Kiến trúc tổng quan

- **Flutter app**: `meetingmind_ai`
- **Backend Flask**: `meetingmind_ai_backend`
- **Database**: MongoDB
- **Realtime**: Socket.IO
- **AI**: OpenAI (summary + embedding), Speechmatics (speech-to-text)

## Yêu cầu môi trường

- Flutter SDK (khuyến nghị phiên bản ổn định mới nhất)
- Dart SDK đi kèm Flutter
- Python 3.10+ cho backend
- MongoDB (local hoặc Atlas)
- API keys: OpenAI, Speechmatics

## Cài đặt & chạy dự án

### 1) Backend

Thư mục: `meetingmind_ai_backend`

1. Tạo môi trường ảo và cài dependencies:
   - Windows: tạo venv, kích hoạt, rồi chạy cài đặt từ `requirements.txt`.
2. Cấu hình biến môi trường trong `.env`:

```
SECRET_KEY=your_secret_key
MONGO_URI=mongodb://localhost:27017/meetingmind
OPENAI_API_KEY=your_openai_api_key
SPEECHMATICS_API_KEY=your_speechmatics_api_key
```

3. Chạy server:

```
python run.py
```

Mặc định backend chạy ở `http://localhost:5000`.

### 2) Flutter app

Thư mục: `meetingmind_ai`

1. Cài dependencies:

```
flutter pub get
```

2. Cập nhật base URL nếu cần (xem `lib/config/api_config.dart`).

3. Chạy app:

```
flutter run
```

## API chính (tham khảo)

- Meetings: `GET /meetings?user_id=...`
- Summarize: `GET /summarize/<sid>`
- Chat meeting: `POST /chat/meeting`
- Chat notebook: `POST /chat/notebook`
- Reminders: `POST /reminder/add`, `GET /reminder/day`
- Search: `GET /search?q=...&user_id=...`
- Teams: `POST /teams/create`, `GET /teams`, `POST /teams/<id>/invite`

## Cấu trúc thư mục (rút gọn)

```
meetingmind/
	meetingmind_ai/           # Flutter app
	meetingmind_ai_backend/   # Flask backend
```

## Lưu ý triển khai

- Cần cấu hình API keys trước khi chạy.
- Nếu dùng thiết bị thật, hãy trỏ base URL về IP LAN của máy chạy backend.

## Đóng góp

PRs luôn được chào đón. Hãy mô tả rõ thay đổi và lý do.

## License

TBD
