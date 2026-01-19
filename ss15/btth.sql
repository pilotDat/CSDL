
DROP DATABASE IF EXISTS SocialNetworkDB;
CREATE DATABASE SocialNetworkDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE SocialNetworkDB;

-- ============================================
-- 1. BẢNG GỐC
-- ============================================

CREATE TABLE Users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Posts (
    post_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    like_count INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
        ON DELETE CASCADE
);

CREATE TABLE Comments (
    comment_id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES Posts(post_id)
        ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
        ON DELETE CASCADE
);

CREATE TABLE Likes (
    user_id INT NOT NULL,
    post_id INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, post_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
        ON DELETE CASCADE,
    FOREIGN KEY (post_id) REFERENCES Posts(post_id)
        ON DELETE CASCADE
);

CREATE TABLE Friends (
    user_id INT NOT NULL,
    friend_id INT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending'
        CHECK (status IN ('pending', 'accepted')),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, friend_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
        ON DELETE CASCADE,
    FOREIGN KEY (friend_id) REFERENCES Users(user_id)
        ON DELETE CASCADE
);

-- ============================================
-- 2. BẢNG LOG
-- ============================================

CREATE TABLE user_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    action VARCHAR(100),
    log_time DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE post_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT,
    action VARCHAR(100),
    log_time DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE like_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    post_id INT,
    action VARCHAR(100),
    log_time DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE friend_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    friend_id INT,
    action VARCHAR(100),
    log_time DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 3. TRIGGER
-- ============================================

-- Bài 1: Log đăng ký
DELIMITER //
CREATE TRIGGER trg_after_user_insert
AFTER INSERT ON Users
FOR EACH ROW
BEGIN
    INSERT INTO user_log(user_id, action)
    VALUES (NEW.user_id, 'User registered');
END;
//
DELIMITER ;

-- Bài 2: Log đăng bài
DELIMITER //
CREATE TRIGGER trg_after_post_insert
AFTER INSERT ON Posts
FOR EACH ROW
BEGIN
    INSERT INTO post_log(post_id, action)
    VALUES (NEW.post_id, 'Post created');
END;
//
DELIMITER ;

-- Bài 3: Like / Unlike update + log
DELIMITER //
CREATE TRIGGER trg_after_like_insert
AFTER INSERT ON Likes
FOR EACH ROW
BEGIN
    UPDATE Posts SET like_count = like_count + 1
    WHERE post_id = NEW.post_id;

    INSERT INTO like_log(user_id, post_id, action)
    VALUES (NEW.user_id, NEW.post_id, 'Like');
END;
//
DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_after_like_delete
AFTER DELETE ON Likes
FOR EACH ROW
BEGIN
    UPDATE Posts SET like_count = like_count - 1
    WHERE post_id = OLD.post_id;

    INSERT INTO like_log(user_id, post_id, action)
    VALUES (OLD.user_id, OLD.post_id, 'Unlike');
END;
//
DELIMITER ;

-- Bài 4 + 5: Log friend
DELIMITER //
CREATE TRIGGER trg_after_friend_insert
AFTER INSERT ON Friends
FOR EACH ROW
BEGIN
    INSERT INTO friend_log(user_id, friend_id, action)
    VALUES (NEW.user_id, NEW.friend_id, CONCAT('Friend request: ', NEW.status));
END;
//
DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_after_friend_update
AFTER UPDATE ON Friends
FOR EACH ROW
BEGIN
    IF NEW.status = 'accepted' AND OLD.status <> 'accepted' THEN
        -- tạo bản ghi ngược nếu chưa có
        IF NOT EXISTS (
            SELECT 1 FROM Friends
            WHERE user_id = NEW.friend_id AND friend_id = NEW.user_id
        ) THEN
            INSERT INTO Friends(user_id, friend_id, status)
            VALUES (NEW.friend_id, NEW.user_id, 'accepted');
        END IF;

        INSERT INTO friend_log(user_id, friend_id, action)
        VALUES (NEW.user_id, NEW.friend_id, 'Friend request accepted');
    END IF;
END;
//
DELIMITER ;

-- ============================================
-- 4. STORED PROCEDURE
-- ============================================

-- BÀI 1: Đăng ký user
DELIMITER //
CREATE PROCEDURE sp_register_user(
    IN p_username VARCHAR(50),
    IN p_password VARCHAR(255),
    IN p_email VARCHAR(100)
)
BEGIN
    IF EXISTS (SELECT 1 FROM Users WHERE username = p_username) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Username already exists';
    ELSEIF EXISTS (SELECT 1 FROM Users WHERE email = p_email) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Email already exists';
    ELSE
        INSERT INTO Users(username, password, email)
        VALUES (p_username, p_password, p_email);
    END IF;
END;
//
DELIMITER ;

-- BÀI 2: Tạo bài viết
DELIMITER //
CREATE PROCEDURE sp_create_post(
    IN p_user_id INT,
    IN p_content TEXT
)
BEGIN
    IF p_content IS NULL OR LENGTH(TRIM(p_content)) = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Post content cannot be empty';
    ELSE
        INSERT INTO Posts(user_id, content)
        VALUES (p_user_id, p_content);
    END IF;
END;
//
DELIMITER ;

-- BÀI 4: Gửi lời mời kết bạn
DELIMITER //
CREATE PROCEDURE sp_send_friend_request(
    IN p_sender_id INT,
    IN p_receiver_id INT
)
BEGIN
    IF p_sender_id = p_receiver_id THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot send friend request to yourself';
    ELSEIF EXISTS (
        SELECT 1 FROM Friends
        WHERE user_id = p_sender_id AND friend_id = p_receiver_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Friend request already exists';
    ELSE
        INSERT INTO Friends(user_id, friend_id, status)
        VALUES (p_sender_id, p_receiver_id, 'pending');
    END IF;
END;
//
DELIMITER ;

-- BÀI 5: Chấp nhận lời mời
DELIMITER //
CREATE PROCEDURE sp_accept_friend_request(
    IN p_sender_id INT,
    IN p_receiver_id INT
)
BEGIN
    UPDATE Friends
    SET status = 'accepted'
    WHERE user_id = p_sender_id AND friend_id = p_receiver_id;
END;
//
DELIMITER ;

-- BÀI 6: Quản lý mối quan hệ (update/delete đối xứng)
DELIMITER //
CREATE PROCEDURE sp_update_friendship_status(
    IN p_user1 INT,
    IN p_user2 INT,
    IN p_new_status VARCHAR(20)
)
BEGIN
    START TRANSACTION;
    UPDATE Friends SET status = p_new_status
    WHERE user_id = p_user1 AND friend_id = p_user2;

    UPDATE Friends SET status = p_new_status
    WHERE user_id = p_user2 AND friend_id = p_user1;

    COMMIT;
END;
//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_delete_friendship(
    IN p_user1 INT,
    IN p_user2 INT
)
BEGIN
    START TRANSACTION;
    DELETE FROM Friends WHERE user_id = p_user1 AND friend_id = p_user2;
    DELETE FROM Friends WHERE user_id = p_user2 AND friend_id = p_user1;
    COMMIT;
END;
//
DELIMITER ;

-- BÀI 7: Xóa bài viết
DELIMITER //
CREATE PROCEDURE sp_delete_post(
    IN p_post_id INT,
    IN p_user_id INT
)
BEGIN
    START TRANSACTION;

    IF NOT EXISTS (
        SELECT 1 FROM Posts
        WHERE post_id = p_post_id AND user_id = p_user_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'You are not the owner of this post';
    ELSE
        DELETE FROM Posts WHERE post_id = p_post_id;
    END IF;

    COMMIT;
END;
//
DELIMITER ;

-- BÀI 8: Xóa tài khoản
DELIMITER //
CREATE PROCEDURE sp_delete_user(
    IN p_user_id INT
)
BEGIN
    START TRANSACTION;
    DELETE FROM Users WHERE user_id = p_user_id;
    COMMIT;
END;
//
DELIMITER ;

-- ============================================
-- 5. KIỂM TRA & DEMO
-- ============================================

-- ========= BÀI 1: ĐĂNG KÝ =========
CALL sp_register_user('huy', '123456', 'huy@gmail.com');
CALL sp_register_user('linh', '123456', 'linh@gmail.com');
CALL sp_register_user('nam', '123456', 'nam@gmail.com');
CALL sp_register_user('mai', '123456', 'mai@gmail.com');

-- Test trùng username/email (sẽ lỗi)
-- CALL sp_register_user('huy', 'abc', 'huy2@gmail.com');
-- CALL sp_register_user('newuser', 'abc', 'huy@gmail.com');

SELECT * FROM Users;
SELECT * FROM user_log;

-- ========= BÀI 2: ĐĂNG BÀI =========
CALL sp_create_post(1, 'Hello world!');
CALL sp_create_post(1, 'Post thứ 2 của Huy');
CALL sp_create_post(2, 'Linh xin chào mọi người');
CALL sp_create_post(3, 'Nam đang học SQL');
CALL sp_create_post(4, 'Mai thích lập trình');

-- Test content rỗng (sẽ lỗi)
-- CALL sp_create_post(1, '');

SELECT * FROM Posts;
SELECT * FROM post_log;

-- ========= BÀI 3: LIKE / UNLIKE =========
INSERT INTO Likes(user_id, post_id) VALUES (2, 1);
INSERT INTO Likes(user_id, post_id) VALUES (3, 1);
INSERT INTO Likes(user_id, post_id) VALUES (4, 1);
INSERT INTO Likes(user_id, post_id) VALUES (1, 2);
INSERT INTO Likes(user_id, post_id) VALUES (3, 2);

-- Unlike
DELETE FROM Likes WHERE user_id = 3 AND post_id = 1;

-- Test like trùng (sẽ lỗi)
-- INSERT INTO Likes(user_id, post_id) VALUES (2, 1);

SELECT post_id, content, like_count FROM Posts;
SELECT * FROM like_log;

-- ========= BÀI 4: GỬI LỜI MỜI =========
CALL sp_send_friend_request(1, 2);
CALL sp_send_friend_request(1, 3);
CALL sp_send_friend_request(2, 3);
CALL sp_send_friend_request(3, 4);

-- Test gửi cho chính mình (sẽ lỗi)
-- CALL sp_send_friend_request(1, 1);

-- Test gửi trùng (sẽ lỗi)
-- CALL sp_send_friend_request(1, 2);

SELECT * FROM Friends;
SELECT * FROM friend_log;

-- ========= BÀI 5: CHẤP NHẬN =========
CALL sp_accept_friend_request(1, 2);
CALL sp_accept_friend_request(1, 3);
CALL sp_accept_friend_request(2, 3);

SELECT * FROM Friends WHERE status = 'accepted';

-- ========= BÀI 6: QUẢN LÝ MỐI QUAN HỆ =========
CALL sp_update_friendship_status(1, 2, 'accepted');

CALL sp_delete_friendship(1, 3);

SELECT * FROM Friends;

-- ========= BÀI 7: XÓA BÀI VIẾT =========
-- Tạo thêm comment + like để test
INSERT INTO Comments(post_id, user_id, content) VALUES (1, 2, 'Hay quá');
INSERT INTO Comments(post_id, user_id, content) VALUES (1, 3, 'Chuẩn luôn');

CALL sp_delete_post(1, 1);

-- Test xóa bài không phải chủ (sẽ lỗi)
-- CALL sp_delete_post(2, 3);

SELECT * FROM Posts;
SELECT * FROM Likes;
SELECT * FROM Comments;

-- ========= BÀI 8: XÓA TÀI KHOẢN =========
CALL sp_delete_user(4);

SELECT * FROM Users;
SELECT * FROM Posts;
SELECT * FROM Comments;
SELECT * FROM Likes;
SELECT * FROM Friends;
