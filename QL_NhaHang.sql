USE master;
GO

-- 1. KIỂM TRA VÀ TẠO DATABASE
IF DB_ID(N'QL_NhaHang') IS NOT NULL
BEGIN
    ALTER DATABASE QL_NhaHang SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE QL_NhaHang;
END
GO

CREATE DATABASE QL_NhaHang;
GO

USE QL_NhaHang;
GO

-- 2. TẠO CÁC BẢNG (TABLES)
CREATE TABLE KhachHang (
    MaKhachHang INT PRIMARY KEY IDENTITY(1,1),
    TenKhachHang NVARCHAR(100) NOT NULL,
    SoDienThoai VARCHAR(15) UNIQUE,
    DiaChi NVARCHAR(255)
);

CREATE TABLE BanAn (
    MaBan INT PRIMARY KEY IDENTITY(1,1),
    SoBan INT NOT NULL,
    TrangThai NVARCHAR(50) DEFAULT N'Trống'
);

CREATE TABLE ThucDon (
    MaMonAn INT PRIMARY KEY IDENTITY(1,1),
    TenMon NVARCHAR(100) NOT NULL UNIQUE,
    DonGia DECIMAL(10, 2) NOT NULL CHECK (DonGia >= 0)
);

CREATE TABLE DatBan (
    MaDatBan INT PRIMARY KEY IDENTITY(1,1),
    MaKhachHang INT FOREIGN KEY REFERENCES KhachHang(MaKhachHang),
    MaBan INT FOREIGN KEY REFERENCES BanAn(MaBan),
    NgayGio DATETIME NOT NULL,
    SoNguoi INT DEFAULT 1
);

CREATE TABLE HoaDon (
    MaHoaDon INT PRIMARY KEY IDENTITY(1,1),
    MaKhachHang INT FOREIGN KEY REFERENCES KhachHang(MaKhachHang),
    MaBan INT FOREIGN KEY REFERENCES BanAn(MaBan),
    NgayThanhToan DATETIME DEFAULT GETDATE(),
    TongTien DECIMAL(18, 2) DEFAULT 0,
    TrangThai NVARCHAR(50) DEFAULT N'Chưa thanh toán'
);

CREATE TABLE ChiTietHoaDon (
    MaHoaDon INT FOREIGN KEY REFERENCES HoaDon(MaHoaDon),
    MaMonAn INT FOREIGN KEY REFERENCES ThucDon(MaMonAn),
    SoLuong INT NOT NULL CHECK (SoLuong > 0),
    DonGia DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (MaHoaDon, MaMonAn)
);
GO

-- 3. CHÈN DỮ LIỆU MẪU (INSERT)

-- Chèn KhachHang
INSERT INTO KhachHang (TenKhachHang, SoDienThoai, DiaChi) VALUES
(N'Nguyễn Văn An', '0901234567', N'123 Lê Lợi, Q1, TPHCM'),
(N'Trần Thị Bích', '0912345678', N'456 Hai Bà Trưng, Hà Nội'),
(N'Phạm Văn Cường', '0987654321', N'789 Nguyễn Trãi, Đà Nẵng'),
(N'Lê Thị Dung', '0909090909', N'101 Võ Văn Tần, Q3, TPHCM'),
(N'Hoàng Văn E', '0888888888', N'202 Hùng Vương, Huế');

-- Chèn BanAn
INSERT INTO BanAn (SoBan, TrangThai) VALUES
(1, N'Trống'),
(2, N'Trống'),
(3, N'Có khách'),
(4, N'Đã đặt'),
(5, N'Trống');

-- Chèn ThucDon
INSERT INTO ThucDon (TenMon, DonGia) VALUES
(N'Phở Bò', 50000.00),
(N'Cơm Gà Xối Mỡ', 45000.00),
(N'Bún Chả Hà Nội', 60000.00),
(N'Gỏi Cuốn', 30000.00),
(N'Nước Cam Vắt', 25000.00),
(N'Cà Phê Sữa Đá', 20000.00);

-- Chèn DatBan
INSERT INTO DatBan (MaKhachHang, MaBan, NgayGio, SoNguoi) VALUES
(1, 4, '2025-11-06 19:00:00', 4),
(2, 4, '2025-11-06 05:40:43', 4),
(3, 4, '2025-11-06 18:00:06', 4),
(4, 4, '2025-11-06 12:30:00', 4),
(5, 4, '2025-11-06 11:00:06', 4);

-- Chèn HoaDon (Sử dụng biến để lưu ID vừa chèn)
DECLARE @MaHD_1 INT, @MaHD_2 INT, @MaHD_3 INT, @MaHD_4 INT, @MaHD_5 INT;

INSERT INTO HoaDon (MaKhachHang, MaBan, NgayThanhToan, TrangThai) VALUES
(2, 3, GETDATE(), N'Chưa thanh toán');
SET @MaHD_1 = SCOPE_IDENTITY();

INSERT INTO HoaDon (MaKhachHang, MaBan, NgayThanhToan, TrangThai) VALUES
(1, 1, '2025-11-05 14:30:00', N'Đã thanh toán');
SET @MaHD_2 = SCOPE_IDENTITY();

INSERT INTO HoaDon (MaKhachHang, MaBan, NgayThanhToan, TrangThai) VALUES
(3, 2, '2025-11-05 19:45:00', N'Đã thanh toán');
SET @MaHD_3 = SCOPE_IDENTITY();

INSERT INTO HoaDon (MaKhachHang, MaBan, NgayThanhToan, TrangThai) VALUES
(4, 5, '2025-11-06 13:15:00', N'Đã thanh toán');
SET @MaHD_4 = SCOPE_IDENTITY();

INSERT INTO HoaDon (MaKhachHang, MaBan, NgayThanhToan, TrangThai) VALUES
(5, 1, '2025-11-06 20:00:00', N'Đã thanh toán');
SET @MaHD_5 = SCOPE_IDENTITY();

-- Chèn ChiTietHoaDon
INSERT INTO ChiTietHoaDon (MaHoaDon, MaMonAn, SoLuong, DonGia) VALUES
(@MaHD_1, 1, 2, 50000.00), -- Phở Bò
(@MaHD_1, 5, 1, 25000.00), -- Nước Cam Vắt
(@MaHD_1, 6, 1, 20000.00), -- Cà Phê Sữa Đá
(@MaHD_2, 1, 1, 50000.00),
(@MaHD_2, 6, 1, 20000.00),
(@MaHD_3, 3, 2, 60000.00),
(@MaHD_3, 4, 3, 30000.00),
(@MaHD_4, 2, 1, 45000.00),
(@MaHD_4, 5, 2, 25000.00),
(@MaHD_5, 1, 1, 50000.00),
(@MaHD_5, 3, 1, 60000.00),
(@MaHD_5, 5, 1, 25000.00);
GO



-- ---  BẢNG KHACHHANG ---
-- Update
UPDATE KhachHang SET DiaChi = N'999 Trần Hưng Đạo, Q1, TPHCM' WHERE MaKhachHang = 1;
UPDATE KhachHang SET SoDienThoai = '0999888777' WHERE TenKhachHang = N'Trần Thị Bích';
UPDATE KhachHang SET TenKhachHang = N'HOÀNG VĂN E' WHERE MaKhachHang = 5;
-- Delete (Ví dụ xóa dữ liệu không ràng buộc hoặc dữ liệu rác)
DELETE FROM KhachHang WHERE MaKhachHang = 100; -- Mã không tồn tại
DELETE FROM KhachHang WHERE SoDienThoai = '0000000000';
DELETE FROM KhachHang WHERE DiaChi IS NULL;

-- --- BẢNG BANAN ---
-- Update
UPDATE BanAn SET TrangThai = N'Đang sửa chữa' WHERE SoBan = 2;
UPDATE BanAn SET TrangThai = N'Trống' WHERE SoBan = 3;
UPDATE BanAn SET SoBan = 10 WHERE MaBan = 5;
-- Delete
DELETE FROM BanAn WHERE MaBan = 200;
DELETE FROM BanAn WHERE TrangThai = N'Hỏng';
DELETE FROM BanAn WHERE SoBan = 99;

-- ---  BẢNG THUCDON ---
-- Update
UPDATE ThucDon SET DonGia = 55000.00 WHERE TenMon = N'Phở Bò';
UPDATE ThucDon SET TenMon = N'Nước Cam Tươi' WHERE TenMon = N'Nước Cam Vắt';
UPDATE ThucDon SET DonGia = DonGia * 0.9 WHERE DonGia > 50000;
-- Delete
DELETE FROM ThucDon WHERE MaMonAn = 150;
DELETE FROM ThucDon WHERE TenMon = N'Trà đá';
DELETE FROM ThucDon WHERE DonGia = 0;

-- ---  BẢNG DATBAN ---
-- Update
UPDATE DatBan SET SoNguoi = 6 WHERE MaDatBan = 1;
UPDATE DatBan SET NgayGio = DATEADD(day, 1, NgayGio) WHERE MaKhachHang = 2;
UPDATE DatBan SET MaBan = 5 WHERE MaDatBan = 3;
-- Delete
DELETE FROM DatBan WHERE MaDatBan = 2;
DELETE FROM DatBan WHERE YEAR(NgayGio) < 2024;
DELETE FROM DatBan WHERE MaKhachHang = 99;

-- ---  BẢNG HOADON ---
-- Update
UPDATE HoaDon SET TrangThai = N'Đã thanh toán', NgayThanhToan = GETDATE() WHERE MaHoaDon = 1;
UPDATE HoaDon SET TongTien = (SELECT SUM(SoLuong * DonGia) FROM ChiTietHoaDon WHERE MaHoaDon = 2) WHERE MaHoaDon = 2;
UPDATE HoaDon SET MaBan = 5 WHERE MaHoaDon = 3;
-- Delete
DELETE FROM HoaDon WHERE MaHoaDon = 1000;
DELETE FROM HoaDon WHERE TrangThai = N'Hủy';
DELETE FROM HoaDon WHERE TongTien = 0;

-- --- BẢNG CHITIETHOADON ---
-- Update
UPDATE ChiTietHoaDon SET SoLuong = 3 WHERE MaHoaDon = 1 AND MaMonAn = 1;
UPDATE ChiTietHoaDon SET DonGia = 40000 WHERE MaHoaDon = 2 AND MaMonAn = 1;
UPDATE ChiTietHoaDon SET MaMonAn = 6, DonGia = (SELECT DonGia FROM ThucDon WHERE MaMonAn = 6) WHERE MaHoaDon = 4 AND MaMonAn = 5;
-- Delete
DELETE FROM ChiTietHoaDon WHERE MaHoaDon = 1 AND MaMonAn = 1;
DELETE FROM ChiTietHoaDon WHERE MaHoaDon = 10;
DELETE FROM ChiTietHoaDon WHERE SoLuong <= 0;
GO