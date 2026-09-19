# PDF Citation Audit — Flutter client

Flutter chỉ chọn PDF, gửi file đến FastAPI và hiển thị report server trả về. Không có parser PDF, Crossref hay LLM chạy trong client.

URL server nằm trong `.env`:

```env
BACKEND_BASE_URL=http://127.0.0.1:8000/api/v1/
```

1. Khởi động backend trong `D:\PRM\prm323_lab1_be`.
2. Chạy Flutter desktop từ thư mục này.
3. Chọn **Import PDF** để upload. Khi hoàn tất, bấm **Bắt đầu phân tích** để chạy parser và Crossref trên backend. Nút **Hủy** dừng request hiện tại và gửi request cancel tới backend.

Xem API và cấu hình server trong README của backend.
