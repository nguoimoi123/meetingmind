# MeetingMind Admin Web

Web admin React tach rieng cho `MeetingMind`.

## Muc tieu

- login admin
- xem giao dich nang cap
- loc giao dich theo plan / payment / code status
- tim user theo id / email / ten
- issue / resend / revoke code
- theo doi giao dich VNPAY

## Cau truc

- `package.json`: React + Vite app
- `index.html`: shell cua app
- `.env.example`: backend URL cho frontend
- `src/App.jsx`: root app
- `src/components/LoginScreen.jsx`: man hinh login
- `src/components/AdminDashboard.jsx`: dashboard admin
- `src/lib/api.js`: helper goi backend
- `src/lib/storage.js`: luu auth local
- `src/styles.css`: giao dien chung

## Cach chay

1. Tao file `.env` trong folder nay tu `.env.example`
2. Dien:

```env
VITE_BACKEND_BASE_URL=http://localhost:5000
```

3. Cai dependency:

```powershell
npm.cmd install
```

4. Chay dev server:

```powershell
npm.cmd run dev
```

5. Mo dia chi Vite hien ra, dang nhap bang `ADMIN_DASHBOARD_KEY`
