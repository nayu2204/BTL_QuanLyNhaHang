USE QL_NhaHang;
GO

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_KhachHang_SDT' AND object_id = OBJECT_ID('KhachHang'))
BEGIN
    DROP INDEX idx_KhachHang_SDT ON KhachHang;
END
GO

CREATE INDEX idx_KhachHang_SDT
ON KhachHang (SoDienThoai);
GO

------View
IF OBJECT_ID('vw_ChiTietHoaDonDayDu', 'V') IS NOT NULL
BEGIN
    DROP VIEW vw_ChiTietHoaDonDayDu;
END
GO

CREATE VIEW vw_ChiTietHoaDonDayDu AS
SELECT
    hd.MaHoaDon,
    kh.TenKhachHang,
    ba.SoBan,
    td.TenMon,
    ct.SoLuong,
    ct.DonGia,
    (ct.SoLuong * ct.DonGia) AS ThanhTien
FROM HoaDon hd
JOIN KhachHang kh ON hd.MaKhachHang = kh.MaKhachHang
JOIN BanAn ba ON hd.MaBan = ba.MaBan
JOIN ChiTietHoaDon ct ON hd.MaHoaDon = ct.MaHoaDon
JOIN ThucDon td ON ct.MaMonAn = td.MaMonAn;
GO
SELECT * FROM vw_ChiTietHoaDonDayDu ;
GO

-------Thủ tục
IF OBJECT_ID('sp_ThemMonVaoHoaDon', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_ThemMonVaoHoaDon;
END
GO

-- Bước 2: Tạo Procedure mới
CREATE PROCEDURE sp_ThemMonVaoHoaDon
    @MaHoaDon INT,
    @MaMonAn INT,
    @SoLuong INT
AS
BEGIN
    -- 1. Lấy đơn giá tại thời điểm đặt
    DECLARE @DonGia DECIMAL(10, 2);
    SELECT @DonGia = DonGia FROM ThucDon WHERE MaMonAn = @MaMonAn;

    -- Kiểm tra xem món ăn có tồn tại trong thực đơn không
    IF @DonGia IS NULL
    BEGIN
        -- Báo lỗi nếu MaMonAn không hợp lệ
        RAISERROR(N'Mã món ăn không tồn tại trong Thực Đơn.', 16, 1);
        RETURN;
    END

    -- 2. Xử lý ChiTietHoaDon
    IF EXISTS (SELECT 1 FROM ChiTietHoaDon WHERE MaHoaDon = @MaHoaDon AND MaMonAn = @MaMonAn)
    BEGIN
        UPDATE ChiTietHoaDon
        SET SoLuong = SoLuong + @SoLuong
        WHERE MaHoaDon = @MaHoaDon AND MaMonAn = @MaMonAn;
    END
    ELSE
    BEGIN
        -- Món chưa có, thêm mới
        INSERT INTO ChiTietHoaDon (MaHoaDon, MaMonAn, SoLuong, DonGia)
        VALUES (@MaHoaDon, @MaMonAn, @SoLuong, @DonGia);
    END

    UPDATE HoaDon
    SET TongTien = (
        SELECT ISNULL(SUM(SoLuong * DonGia), 0)
        FROM ChiTietHoaDon
        WHERE MaHoaDon = @MaHoaDon
    )
    WHERE MaHoaDon = @MaHoaDon;
END;
GO
-- Thêm 1 'Bún Chả Hà Nội' (MaMonAn = 3) vào hóa đơn 1
EXEC sp_ThemMonVaoHoaDon @MaHoaDon = 1, @MaMonAn = 3, @SoLuong = 1;

-- Xem kết quả
SELECT * FROM vw_ChiTietHoaDonDayDu ;
GO
---triggle-------
IF OBJECT_ID('trg_CapNhatTongTien', 'TR') IS NOT NULL
    DROP TRIGGER trg_CapNhatTongTien;
GO

CREATE TRIGGER trg_CapNhatTongTien
ON ChiTietHoaDon
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- 1. Khai báo bảng tạm để chứa các MaHoaDon bị ảnh hưởng
    DECLARE @AffectedHoaDon TABLE (MaHoaDon INT PRIMARY KEY);

    -- 2. Đưa các MaHoaDon từ các bảng ảo 'inserted' và 'deleted' vào bảng tạm
    -- (Bao gồm các hóa đơn bị ảnh hưởng bởi INSERT, DELETE, và UPDATE)
    INSERT INTO @AffectedHoaDon (MaHoaDon)
    SELECT MaHoaDon FROM inserted
    UNION
    SELECT MaHoaDon FROM deleted;
    UPDATE HD
    SET
        HD.TongTien = ISNULL(
            -- Tính tổng tiền mới từ ChiTietHoaDon hiện tại
            (SELECT SUM(CT.SoLuong * CT.DonGia)
             FROM ChiTietHoaDon CT
             WHERE CT.MaHoaDon = HD.MaHoaDon), 0)
    FROM HoaDon HD
    INNER JOIN @AffectedHoaDon AHD ON HD.MaHoaDon = AHD.MaHoaDon;
END;
GO

-----hàm----
IF OBJECT_ID('fn_TinhTongDoanhThuTheoNgay', 'FN') IS NOT NULL
BEGIN
    DROP FUNCTION fn_TinhTongDoanhThuTheoNgay;
END
GO

CREATE FUNCTION fn_TinhTongDoanhThuTheoNgay
(
    @Ngay DATE
)
RETURNS DECIMAL(18, 2)
AS
BEGIN
    DECLARE @TongDoanhThu DECIMAL(18, 2);

    SELECT @TongDoanhThu = SUM(TongTien)
    FROM HoaDon
    WHERE TrangThai = N'Đã thanh toán'
      AND CONVERT(DATE, NgayThanhToan) = @Ngay;
    RETURN ISNULL(@TongDoanhThu, 0);
END;
GO

SELECT dbo.fn_TinhTongDoanhThuTheoNgay(CONVERT(DATE, GETDATE())) AS DoanhThuHomNay;
GO
---thủ tục--
IF OBJECT_ID('sp_ThanhToanHoaDon', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_ThanhToanHoaDon;
END
GO
CREATE PROCEDURE sp_ThanhToanHoaDon
    @MaHoaDon INT
AS
BEGIN
    BEGIN TRANSACTION
    DECLARE @TongTien DECIMAL(18, 2);
    DECLARE @MaBan INT;
    DECLARE @TrangThaiHienTai NVARCHAR(50);
    -- 0. Kiểm tra Hóa đơn có tồn tại không
    SELECT @MaBan = MaBan, @TrangThaiHienTai = TrangThai
    FROM HoaDon
    WHERE MaHoaDon = @MaHoaDon;

    IF @MaBan IS NULL
    BEGIN
        RAISERROR(N'Mã hóa đơn không hợp lệ.', 16, 1);
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        RETURN;
    END

    IF @TrangThaiHienTai = N'Đã thanh toán'
    BEGIN
        RAISERROR(N'Hóa đơn này đã được thanh toán trước đó.', 16, 1);
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        RETURN;
    END
    -- 1. Tính tổng tiền từ ChiTietHoaDon
    SELECT @TongTien = ISNULL(SUM(SoLuong * DonGia), 0)
    FROM ChiTietHoaDon
    WHERE MaHoaDon = @MaHoaDon;
    -- 2. Cập nhật tổng tiền và trạng thái cho HoaDon
    UPDATE HoaDon
    SET
        TongTien = @TongTien,
        TrangThai = N'Đã thanh toán',
        NgayThanhToan = GETDATE()
    WHERE MaHoaDon = @MaHoaDon;
    IF @@ERROR <> 0 GOTO ERROR_HANDLER;
    -- 3. Cập nhật trạng thái bàn về 'Trống'
    UPDATE BanAn
    SET TrangThai = N'Trống'
    WHERE MaBan = @MaBan;
    IF @@ERROR <> 0 GOTO ERROR_HANDLER;
    COMMIT TRANSACTION;
    SELECT N'Thanh toán thành công' AS KetQua, * FROM HoaDon WHERE MaHoaDon = @MaHoaDon;
    RETURN;

ERROR_HANDLER:
    -- Xử lý lỗi (ROLLBACK)
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    RAISERROR(N'Đã xảy ra lỗi trong quá trình thanh toán. Giao dịch đã được hoàn tác.', 16, 1);
    RETURN;
END;
GO
SELECT * FROM BanAn WHERE MaBan = 5;--Kiểm tra xem trạng thái Bàn 5 đã tự động chuyển sang 'Có khách' chưa
GO

-----Thủ tục báo cáo món ăn bán chạy
IF OBJECT_ID('sp_BaoCaoMonAnBanChay', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE sp_BaoCaoMonAnBanChay;
END
GO

CREATE PROCEDURE sp_BaoCaoMonAnBanChay
    @TopN INT = 5 -- Tham số để chọn top món ăn 
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Truy vấn tổng hợp dữ liệu từ ChiTietHoaDon và ThucDon
    SELECT TOP (@TopN)
        TD.TenMon,
        SUM(CTHD.SoLuong) AS TongSoLuongBan,
        SUM(CTHD.SoLuong * CTHD.DonGia) AS TongDoanhThu
    FROM
        ChiTietHoaDon CTHD
    INNER JOIN
        ThucDon TD ON CTHD.MaMonAn = TD.MaMonAn
    GROUP BY
        TD.TenMon
    ORDER BY
        TongSoLuongBan DESC, -- Sắp xếp ưu tiên theo số lượng bán
        TongDoanhThu DESC;   -- Sắp xếp thứ hai theo doanh thu
END;
GO
-- Xem 3 món ăn được đặt nhiều nhất
EXEC sp_BaoCaoMonAnBanChay @TopN = 3;
GO
--Sao lưu (Backup) cơ sở dữ liệu
BACKUP DATABASE QL_NhaHang
TO DISK = 'D:\backupfilesql\QL_NhaHang_Full.bak'
WITH NAME = 'QL_NhaHang Full Backup',
     INIT,  -- Ghi đè nếu file đã tồn tại
     FORMAT;
GO
