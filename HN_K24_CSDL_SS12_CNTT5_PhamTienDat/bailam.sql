
CREATE DATABASE IF NOT EXISTS StudentManagement;
USE StudentManagement;

-- =============================================
-- 1. TABLE STRUCTURE
-- =============================================

-- Table: Students
CREATE TABLE Students (
    StudentID CHAR(5) PRIMARY KEY,
    FullName VARCHAR(50) NOT NULL,
    TotalDebt DECIMAL(10,2) DEFAULT 0
);

-- Table: Subjects
CREATE TABLE Subjects (
    SubjectID CHAR(5) PRIMARY KEY,
    SubjectName VARCHAR(50) NOT NULL,
    Credits INT CHECK (Credits > 0)
);

-- Table: Grades
CREATE TABLE Grades (
    StudentID CHAR(5),
    SubjectID CHAR(5),
    Score DECIMAL(4,2) CHECK (Score BETWEEN 0 AND 10),
    PRIMARY KEY (StudentID, SubjectID),
    CONSTRAINT FK_Grades_Students FOREIGN KEY (StudentID) REFERENCES Students(StudentID),
    CONSTRAINT FK_Grades_Subjects FOREIGN KEY (SubjectID) REFERENCES Subjects(SubjectID)
);

-- Table: GradeLog
CREATE TABLE GradeLog (
    LogID INT PRIMARY KEY AUTO_INCREMENT,
    StudentID CHAR(5),
    OldScore DECIMAL(4,2),
    NewScore DECIMAL(4,2),
    ChangeDate DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 2. SEED DATA
-- =============================================

-- Insert Students
INSERT INTO Students (StudentID, FullName, TotalDebt) VALUES 
('SV01', 'Ho Khanh Linh', 5000000),
('SV03', 'Tran Thi Khanh Huyen', 0);

-- Insert Subjects
INSERT INTO Subjects (SubjectID, SubjectName, Credits) VALUES 
('SB01', 'Co so du lieu', 3),
('SB02', 'Lap trinh Java', 4),
('SB03', 'Lap trinh C', 3);

-- Insert Grades
INSERT INTO Grades (StudentID, SubjectID, Score) VALUES 
('SV01', 'SB01', 8.5), -- Passed
('SV03', 'SB02', 3.0); -- Failed



-- cau 1:
delimiter $$

create trigger tg_CheckScore
before insert on Grades
for each row
begin
    if new.Score < 0 then
        set new.Score = 0;
    elseif new.Score > 10 then
        set new.Score = 10;
    end if;
end$$

delimiter ;

-- cau 2 :
start transaction;

insert into Students (StudentID, FullName, TotalDebt)
values ('SV02', 'Ha Bich Ngoc', 5000000);

commit;



-- cau 3 : 
delimiter $$
create trigger tg_LogGradeUpdate
after update on Grades
for each row
begin 
	if old.score <> new.score then 
		insert into GradeLog (StudentID, OldScore, NewScore, ChangeDate)
        values (new.StudentID, old.Score, new.Score, now());
	end if;

end $$

delimiter ;

-- cau 4:
delimiter $$
create procedure sp_PayTuition()
begin
	declare v_TotalDebt decimal(10,2);
    start transaction;
    update Students
    set TotalDebt = TotalDebt - 2000000
    where StudentID = 'SV01';
    select TotalDebt
    into v_TotalDebt
    from Students
    where StudentID = 'SV01';
    if v_TotalDebt < 0 then rollback;
    else commit;
    end if;
end $$

delimiter ;

-- cau5 :
delimiter $$

create trigger tg_PreventPassUpdate
before update on Grades
for each row
begin
    if new.Score >= 4.0 then
        signal sqlstate '45000'
        set message_text = 'Khong duoc phep cap nhat diem';
    end if;
end$$

delimiter ;
 




















