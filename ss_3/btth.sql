CREATE DATABASE BTTH;
USE BTTH;

CREATE TABLE SinhVien (
    student_id INT AUTO_INCREMENT,
    full_name VARCHAR(100) NOT NULL,
    date_of_birth DATE,
    gender CHAR(1),
    email VARCHAR(100) NOT NULL,
    phone VARCHAR(15),

    CONSTRAINT pk_sinhvien PRIMARY KEY (student_id),
    CONSTRAINT uq_sinhvien_email UNIQUE (email),
    CONSTRAINT ck_sinhvien_gender CHECK (gender IN ('M', 'F'))
);

CREATE TABLE MonHoc (
    course_id INT,
    course_name VARCHAR(100) NOT NULL,
    credits INT,

    CONSTRAINT pk_monhoc PRIMARY KEY (course_id),
    CONSTRAINT ck_monhoc_credits CHECK (credits > 0)
);

CREATE TABLE DangKy (
    registration_id INT AUTO_INCREMENT,
    student_id INT NOT NULL,
    course_id INT NOT NULL,
    semester VARCHAR(20),
    registration_date DATE DEFAULT (CURRENT_DATE),

    CONSTRAINT pk_dangky PRIMARY KEY (registration_id),
    CONSTRAINT fk_dangky_sinhvien FOREIGN KEY (student_id)
        REFERENCES SinhVien(student_id),
    CONSTRAINT fk_dangky_monhoc FOREIGN KEY (course_id)
        REFERENCES MonHoc(course_id)
);



-- 1. Thêm 10 sinh viên
INSERT INTO SinhVien (full_name, date_of_birth, gender, email, phone) VALUES
('pham tien dat', '2004-01-10', 'M', 'a@gmail.com', '090000001'),
('nguyen quang huy',  '2004-02-15', 'F', 'b@gmail.com', '090000002'),
('nguyen the kien',    '2004-03-20', 'M', 'c@gmail.com', '090000003'),
('le thanh tung',  '2004-04-25', 'F', 'd@gmail.com', '090000004'),
('abcd', '2004-05-30', 'M', 'e@gmail.com', '090000005'),
('efgh',    '2004-06-12', 'F', 'f@gmail.com', '090000006'),
('nguoi am phu',  '2004-07-18', 'M', 'g@gmail.com', '090000007'),
('doraemon',   '2004-08-22', 'F', 'h@gmail.com', '090000008'),
('hifisound',    '2004-09-05', 'M', 'i@gmail.com', '090000009'),
('wuzih audio',   '2004-10-11', 'F', 'k@gmail.com', '090000010');

-- 2. Thêm 10 môn học
INSERT INTO MonHoc (course_id, course_name, credits) VALUES
(101, 'Co so du lieu', 3),
(102, 'Lap trinh C', 3),
(103, 'Lap trinh Java', 4),
(104, 'Mang may tinh', 3),
(105, 'He dieu hanh', 3),
(106, 'Cong nghe Web', 3),
(107, 'Phan tich thiet ke HT', 3),
(108, 'Tri tue nhan tao', 4),
(109, 'Khai pha du lieu', 3),
(110, 'An toan thong tin', 3);

-- 3. Thêm 10 dòng đăng ký
INSERT INTO DangKy (student_id, course_id, semester, registration_date) VALUES
(1, 101, '2024HK1', '2024-09-01'),
(2, 102, '2024HK1', '2024-09-01'),
(3, 103, '2024HK1', '2024-09-02'),
(4, 104, '2024HK1', '2024-09-02'),
(5, 105, '2024HK1', '2024-09-03'),
(6, 106, '2024HK1', '2024-09-03'),
(7, 107, '2024HK1', '2024-09-04'),
(8, 108, '2024HK1', '2024-09-04'),
(9, 109, '2024HK1', '2024-09-05'),
(10,110, '2024HK1', '2024-09-05');



SELECT student_id, full_name
FROM SinhVien;


SELECT course_name, credits
FROM MonHoc;


SELECT student_id, course_id
FROM DangKy;




-- Sửa email sinh viên
UPDATE SinhVien
SET email = 'updated@gmail.com'
WHERE student_id = 1;
-- Giải thích: Cập nhật email cho sinh viên id 1

-- Sửa số tín chỉ môn học
UPDATE MonHoc
SET credits = 4
WHERE course_id = 101;
-- Giải thích: Thay đổi số tín chỉ môn 101

-- Sửa học kỳ đăng ký
UPDATE DangKy
SET semester = '2024HK2'
WHERE registration_id = 1;
-- Giải thích: Đổi học kỳ cho dòng đăng ký mã 1




-- Xóa một dòng đăng ký
DELETE FROM DangKy
WHERE registration_id = 10;
-- Giải thích: Không vi phạm ràng buộc vì không bị tham chiếu

-- Xóa một sinh viên
DELETE FROM SinhVien
WHERE student_id = 10;
-- Giải thích: Sinh viên này không còn đăng ký môn học



