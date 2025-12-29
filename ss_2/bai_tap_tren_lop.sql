
CREATE DATABASE IF NOT EXISTS bai_thuc_hanh_;
USE bai_thuc_hanh_;


CREATE TABLE SinhVien (
    student_id INT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    date_of_birth DATE,
    gender CHAR(1) CHECK (gender IN ('M','F')),
    email VARCHAR(100),
    class_name VARCHAR(50)
);


CREATE TABLE MonHoc (
    subject_id INT PRIMARY KEY,
    subject_name VARCHAR(100) NOT NULL,
    credit_hours INT
);


CREATE TABLE DangKy (
    student_id INT,
    subject_id INT,
    regist_date DATE,
    semester VARCHAR(20),
    PRIMARY KEY (student_id, subject_id),
    FOREIGN KEY (student_id) REFERENCES SinhVien(student_id),
    FOREIGN KEY (subject_id) REFERENCES MonHoc(subject_id)
);




ALTER TABLE SinhVien
ADD phone VARCHAR(15);
-- thêm sđt sih viên


ALTER TABLE SinhVien
ADD CONSTRAINT uq_email UNIQUE (email);
-- thêm email sinh viên, mỗi sinh viên chỉ có duy nhất 1 email 



ALTER TABLE DangKy
MODIFY semester VARCHAR(30);
-- lưu học kỳ chi tiết hơn 


ALTER TABLE MonHoc
ADD CONSTRAINT chk_credit
CHECK (credit_hours BETWEEN 1 AND 5);
-- số tin chỉ hợp lệ từ 1-5 



ALTER TABLE SinhVien
DROP COLUMN class_name;
-- xóa cột class name vì có thể quản lý bằng bảng khác
