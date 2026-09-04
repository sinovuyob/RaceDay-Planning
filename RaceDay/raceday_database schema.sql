-- ============================================================
-- RaceDay Database Schema
-- SQL Server Management Studio (SSMS)
-- Author: [Your Name]
-- Date: September 2026
-- Description: Complete database schema for RaceDay event management system
-- ============================================================

-- ============================================================
-- DROP EXISTING DATABASE (if it exists) - COMMENT OUT FOR PRODUCTION
-- ============================================================
USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'RaceDayDB')
BEGIN
    ALTER DATABASE RaceDayDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE RaceDayDB;
END
GO

-- ============================================================
-- CREATE DATABASE
-- ============================================================
CREATE DATABASE RaceDayDB;
GO

USE RaceDayDB;
GO

-- ============================================================
-- CREATE TABLES
-- ============================================================

-- ============================================================
-- 1. USER TABLE
-- Stores both Organisers and Participants
-- ============================================================
CREATE TABLE [User] (
    user_id INT IDENTITY(1,1) PRIMARY KEY,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('Organiser', 'Participant')),
    date_of_birth DATE NULL,
    phone_number VARCHAR(20) NULL,
    profile_picture_url VARCHAR(500) NULL,
    is_active BIT NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    last_login DATETIME NULL,
    updated_at DATETIME NULL
);
GO

-- ============================================================
-- 2. EVENT TABLE
-- Stores race/event details
-- ============================================================
CREATE TABLE [Event] (
    event_id INT IDENTITY(1,1) PRIMARY KEY,
    organiser_id INT NOT NULL,
    event_name VARCHAR(100) NOT NULL,
    event_date DATE NOT NULL,
    event_time TIME NULL,
    location VARCHAR(200) NOT NULL,
    venue VARCHAR(200) NULL,
    description TEXT NULL,
    max_participants INT NULL,
    registration_deadline DATE NULL,
    event_status VARCHAR(20) NOT NULL DEFAULT 'Upcoming' 
        CHECK (event_status IN ('Draft', 'Upcoming', 'Open', 'Registration Closed', 'In Progress', 'Completed', 'Cancelled')),
    is_public BIT NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    
    CONSTRAINT FK_Event_Organiser FOREIGN KEY (organiser_id) REFERENCES [User](user_id)
);
GO

-- ============================================================
-- 3. CATEGORY TABLE
-- Event categories (e.g., 5km, 10km, Half Marathon)
-- ============================================================
CREATE TABLE Category (
    category_id INT IDENTITY(1,1) PRIMARY KEY,
    event_id INT NOT NULL,
    category_name VARCHAR(50) NOT NULL,
    distance_km DECIMAL(5,2) NOT NULL,
    entry_fee DECIMAL(10,2) NOT NULL,
    age_min INT NULL,
    age_max INT NULL,
    gender_restriction VARCHAR(10) NULL CHECK (gender_restriction IN ('Male', 'Female', 'Mixed', NULL)),
    capacity INT NULL,
    start_time TIME NULL,
    is_active BIT NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    
    CONSTRAINT FK_Category_Event FOREIGN KEY (event_id) REFERENCES [Event](event_id)
);
GO

-- ============================================================
-- 4. ENROLMENT TABLE
-- Links Participants to Events and Categories
-- ============================================================
CREATE TABLE Enrolment (
    enrolment_id INT IDENTITY(1,1) PRIMARY KEY,
    participant_id INT NOT NULL,
    category_id INT NOT NULL,
    event_id INT NOT NULL,
    entry_date DATETIME NOT NULL DEFAULT GETDATE(),
    status VARCHAR(20) NOT NULL DEFAULT 'Registered'
        CHECK (status IN ('Registered', 'Confirmed', 'Paid', 'Cancelled', 'Completed', 'Withdrawn')),
    bib_number INT NULL UNIQUE,
    medical_conditions TEXT NULL,
    emergency_contact VARCHAR(100) NULL,
    emergency_phone VARCHAR(20) NULL,
    payment_status VARCHAR(20) NOT NULL DEFAULT 'Pending'
        CHECK (payment_status IN ('Pending', 'Paid', 'Failed', 'Refunded')),
    payment_reference VARCHAR(100) NULL,
    is_active BIT NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    
    CONSTRAINT FK_Enrolment_Participant FOREIGN KEY (participant_id) REFERENCES [User](user_id),
    CONSTRAINT FK_Enrolment_Category FOREIGN KEY (category_id) REFERENCES Category(category_id),
    CONSTRAINT FK_Enrolment_Event FOREIGN KEY (event_id) REFERENCES [Event](event_id),
    
    -- Ensure a participant can only enrol once per event
    CONSTRAINT UQ_Enrolment_Participant_Event UNIQUE (participant_id, event_id)
);
GO

-- ============================================================
-- 5. RESULT TABLE
-- Stores participant race results
-- ============================================================
CREATE TABLE [Result] (
    result_id INT IDENTITY(1,1) PRIMARY KEY,
    enrolment_id INT NOT NULL,
    finish_time TIME NULL,
    gun_time TIME NULL,
    chip_time TIME NULL,
    overall_position INT NULL,
    category_position INT NULL,
    gender_position INT NULL,
    pace_per_km DECIMAL(5,2) NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Pending'
        CHECK (status IN ('Pending', 'Verified', 'Disqualified', 'DNS', 'DNF')),
    verified_by INT NULL,
    verified_date DATETIME NULL,
    notes TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    
    CONSTRAINT FK_Result_Enrolment FOREIGN KEY (enrolment_id) REFERENCES Enrolment(enrolment_id),
    CONSTRAINT FK_Result_Verifier FOREIGN KEY (verified_by) REFERENCES [User](user_id),
    
    -- Ensure one result per enrolment
    CONSTRAINT UQ_Result_Enrolment UNIQUE (enrolment_id)
);
GO

-- ============================================================
-- 6. WEATHER TABLE
-- Weather information for events
-- ============================================================
CREATE TABLE Weather (
    weather_id INT IDENTITY(1,1) PRIMARY KEY,
    event_id INT NOT NULL,
    forecast_date DATETIME NOT NULL DEFAULT GETDATE(),
    temperature DECIMAL(5,2) NULL,
    conditions VARCHAR(100) NULL,
    humidity INT NULL,
    wind_speed DECIMAL(5,2) NULL,
    wind_direction VARCHAR(20) NULL,
    rainfall_mm DECIMAL(5,2) NULL,
    weather_source VARCHAR(50) NULL,
    is_forecast BIT NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    
    CONSTRAINT FK_Weather_Event FOREIGN KEY (event_id) REFERENCES [Event](event_id)
);
GO

-- ============================================================
-- 7. ROUTE TABLE
-- Route information for events
-- ============================================================
CREATE TABLE Route (
    route_id INT IDENTITY(1,1) PRIMARY KEY,
    event_id INT NOT NULL,
    route_name VARCHAR(100) NULL,
    distance_km DECIMAL(5,2) NOT NULL,
    elevation_gain INT NULL,
    elevation_loss INT NULL,
    start_location VARCHAR(200) NULL,
    finish_location VARCHAR(200) NULL,
    route_description TEXT NULL,
    gpx_file_url VARCHAR(500) NULL,
    water_points INT NULL,
    aid_stations INT NULL,
    is_active BIT NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    
    CONSTRAINT FK_Route_Event FOREIGN KEY (event_id) REFERENCES [Event](event_id)
);
GO

-- ============================================================
-- 8. EVENT_MEDIA TABLE
-- Media files related to events (maps, photos, promotional)
-- ============================================================
CREATE TABLE EventMedia (
    media_id INT IDENTITY(1,1) PRIMARY KEY,
    event_id INT NOT NULL,
    media_type VARCHAR(20) NOT NULL CHECK (media_type IN ('Image', 'Video', 'Document', 'Map', 'Other')),
    media_url VARCHAR(500) NOT NULL,
    description VARCHAR(200) NULL,
    uploaded_by INT NULL,
    upload_date DATETIME NOT NULL DEFAULT GETDATE(),
    is_active BIT NOT NULL DEFAULT 1,
    
    CONSTRAINT FK_EventMedia_Event FOREIGN KEY (event_id) REFERENCES [Event](event_id),
    CONSTRAINT FK_EventMedia_Uploader FOREIGN KEY (uploaded_by) REFERENCES [User](user_id)
);
GO

-- ============================================================
-- 9. NOTIFICATION TABLE (Bonus - for future features)
-- Stores notifications for users
-- ============================================================
CREATE TABLE Notification (
    notification_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    notification_type VARCHAR(50) NOT NULL,
    title VARCHAR(100) NOT NULL,
    message TEXT NOT NULL,
    is_read BIT NOT NULL DEFAULT 0,
    link_url VARCHAR(500) NULL,
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    read_at DATETIME NULL,
    
    CONSTRAINT FK_Notification_User FOREIGN KEY (user_id) REFERENCES [User](user_id)
);
GO

-- ============================================================
-- ============================================================
-- CREATE INDEXES FOR PERFORMANCE
-- ============================================================

-- User Table Indexes
CREATE INDEX IX_User_Email ON [User](email);
CREATE INDEX IX_User_Role ON [User](role);
CREATE INDEX IX_User_IsActive ON [User](is_active);

-- Event Table Indexes
CREATE INDEX IX_Event_OrganiserId ON [Event](organiser_id);
CREATE INDEX IX_Event_EventDate ON [Event](event_date);
CREATE INDEX IX_Event_EventStatus ON [Event](event_status);
CREATE INDEX IX_Event_Location ON [Event](location);

-- Category Table Indexes
CREATE INDEX IX_Category_EventId ON Category(event_id);
CREATE INDEX IX_Category_Distance ON Category(distance_km);
CREATE INDEX IX_Category_IsActive ON Category(is_active);

-- Enrolment Table Indexes
CREATE INDEX IX_Enrolment_ParticipantId ON Enrolment(participant_id);
CREATE INDEX IX_Enrolment_CategoryId ON Enrolment(category_id);
CREATE INDEX IX_Enrolment_EventId ON Enrolment(event_id);
CREATE INDEX IX_Enrolment_Status ON Enrolment(status);
CREATE INDEX IX_Enrolment_PaymentStatus ON Enrolment(payment_status);
CREATE INDEX IX_Enrolment_EntryDate ON Enrolment(entry_date);

-- Result Table Indexes
CREATE INDEX IX_Result_EnrolmentId ON [Result](enrolment_id);
CREATE INDEX IX_Result_Status ON [Result](status);
CREATE INDEX IX_Result_OverallPosition ON [Result](overall_position);
CREATE INDEX IX_Result_CategoryPosition ON [Result](category_position);

-- Weather Table Indexes
CREATE INDEX IX_Weather_EventId ON Weather(event_id);
CREATE INDEX IX_Weather_ForecastDate ON Weather(forecast_date);

-- Route Table Indexes
CREATE INDEX IX_Route_EventId ON Route(event_id);

-- Notification Table Indexes
CREATE INDEX IX_Notification_UserId ON Notification(user_id);
CREATE INDEX IX_Notification_IsRead ON Notification(is_read);
CREATE INDEX IX_Notification_CreatedAt ON Notification(created_at);

-- ============================================================
-- ============================================================
-- SEED DATA - INSERT SAMPLE RECORDS
-- ============================================================

-- ============================================================
-- 1. INSERT USERS (2 Organisers, 3 Participants)
-- ============================================================
INSERT INTO [User] (email, password_hash, full_name, role, date_of_birth, phone_number, is_active)
VALUES 
    -- Organisers
    ('thabo.mbeki@raceday.co.za', 'hashed_password_1', 'Thabo Mbeki', 'Organiser', '1975-06-15', '+27 82 123 4567', 1),
    ('sarah.johnson@raceday.co.za', 'hashed_password_2', 'Sarah Johnson', 'Organiser', '1980-11-22', '+27 83 234 5678', 1),
    
    -- Participants
    ('john.doe@gmail.com', 'hashed_password_3', 'John Doe', 'Participant', '1990-03-10', '+27 84 345 6789', 1),
    ('mary.smith@gmail.com', 'hashed_password_4', 'Mary Smith', 'Participant', '1988-07-25', '+27 85 456 7890', 1),
    ('sipho.ndlovu@yahoo.com', 'hashed_password_5', 'Sipho Ndlovu', 'Participant', '1995-12-05', '+27 86 567 8901', 1);
GO

-- ============================================================
-- 2. INSERT EVENTS
-- ============================================================
INSERT INTO [Event] (organiser_id, event_name, event_date, event_time, location, venue, description, max_participants, registration_deadline, event_status, is_public)
VALUES
    -- Event 1: Comrades Marathon
    (1, 'Comrades Marathon 2026', '2026-06-21', '05:30:00', 'Pietermaritzburg to Durban', 'Pietermaritzburg City Hall', 
     'The ultimate human race - 90km ultra marathon from Pietermaritzburg to Durban. One of the world''s oldest and largest ultra marathons.', 
     25000, '2026-06-01', 'Open', 1),
    
    -- Event 2: Cape Town Cycle Tour
    (2, 'Cape Town Cycle Tour 2026', '2026-03-08', '06:00:00', 'Cape Town', 'Grand Parade, Cape Town', 
     'The world''s largest timed cycle event - 109km scenic route around the Cape Peninsula.', 
     35000, '2026-02-20', 'Upcoming', 1),
    
    -- Event 3: Soweto Marathon
    (1, 'Soweto Marathon 2026', '2026-11-01', '06:30:00', 'Soweto, Johannesburg', 'FNB Stadium', 
     'Known as the ''people''s race'' - 42.2km marathon through the historic streets of Soweto.', 
     15000, '2026-10-15', 'Draft', 1);
GO

-- ============================================================
-- 3. INSERT CATEGORIES
-- ============================================================
INSERT INTO Category (event_id, category_name, distance_km, entry_fee, age_min, age_max, gender_restriction, capacity, start_time, is_active)
VALUES
    -- Comrades Marathon Categories
    (1, 'Comrades Ultimate - Men', 90.0, 1200.00, 20, 65, 'Male', 15000, '05:30:00', 1),
    (1, 'Comrades Ultimate - Women', 90.0, 1200.00, 20, 65, 'Female', 10000, '05:30:00', 1),
    (1, 'Comrades Challenge Walk', 90.0, 800.00, 25, 70, 'Mixed', 2000, '05:30:00', 1),
    
    -- Cape Town Cycle Tour Categories
    (2, 'Elite Men', 109.0, 450.00, 18, 40, 'Male', 3000, '06:00:00', 1),
    (2, 'Elite Women', 109.0, 450.00, 18, 40, 'Female', 2000, '06:00:00', 1),
    (2, 'Open Men', 109.0, 350.00, 18, 99, 'Male', 15000, '06:15:00', 1),
    (2, 'Open Women', 109.0, 350.00, 18, 99, 'Female', 10000, '06:15:00', 1),
    (2, 'Junior (16-17)', 109.0, 250.00, 16, 17, 'Mixed', 1000, '06:30:00', 1),
    
    -- Soweto Marathon Categories
    (3, 'Full Marathon Men', 42.2, 350.00, 18, 70, 'Male', 7000, '06:30:00', 1),
    (3, 'Full Marathon Women', 42.2, 350.00, 18, 70, 'Female', 5000, '06:30:00', 1),
    (3, 'Half Marathon', 21.1, 250.00, 16, 99, 'Mixed', 3000, '07:00:00', 1);
GO

-- ============================================================
-- 4. INSERT ENROLMENTS
-- ============================================================
INSERT INTO Enrolment (participant_id, category_id, event_id, entry_date, status, bib_number, payment_status, payment_reference, emergency_contact, emergency_phone, medical_conditions)
VALUES
    -- John Doe - Comrades Marathon
    (3, 1, 1, DATEADD(DAY, -30, GETDATE()), 'Confirmed', 1001, 'Paid', 'PAY-COM-2026-001', 'Jane Doe', '+27 82 999 8888', 'Asthma - carry inhaler'),
    
    -- Mary Smith - Comrades Marathon
    (4, 2, 1, DATEADD(DAY, -28, GETDATE()), 'Confirmed', 1002, 'Paid', 'PAY-COM-2026-002', 'Tom Smith', '+27 83 777 6666', 'None'),
    
    -- Sipho Ndlovu - Comrades Marathon (walking category)
    (5, 3, 1, DATEADD(DAY, -25, GETDATE()), 'Registered', 1003, 'Pending', NULL, 'Thandi Ndlovu', '+27 84 555 4444', 'Knee injury - requires support'),
    
    -- John Doe - Cape Town Cycle Tour
    (3, 6, 2, DATEADD(DAY, -45, GETDATE()), 'Paid', 2001, 'Paid', 'PAY-CTCT-2026-001', 'Jane Doe', '+27 82 999 8888', 'None'),
    
    -- Mary Smith - Cape Town Cycle Tour
    (4, 7, 2, DATEADD(DAY, -40, GETDATE()), 'Confirmed', 2002, 'Paid', 'PAY-CTCT-2026-002', 'Tom Smith', '+27 83 777 6666', 'None'),
    
    -- Sipho Ndlovu - Cape Town Cycle Tour (Junior)
    (5, 8, 2, DATEADD(DAY, -35, GETDATE()), 'Registered', 2003, 'Pending', NULL, 'Thandi Ndlovu', '+27 84 555 4444', 'None');
GO

-- ============================================================
-- 5. INSERT RESULTS (for completed/ongoing events)
-- ============================================================
-- For Comrades Marathon (mock results)
INSERT INTO [Result] (enrolment_id, finish_time, gun_time, chip_time, overall_position, category_position, gender_position, pace_per_km, status, notes)
VALUES
    (1, '07:45:30', '07:46:00', '07:45:30', 250, 150, 200, 5.10, 'Verified', 'Strong performance'),
    (2, '08:15:45', '08:16:15', '08:15:45', 450, 180, 50, 5.50, 'Verified', 'Good finish'),
    (3, '10:30:00', '10:30:30', '10:30:00', 1500, 500, 700, 7.00, 'Pending', 'Walking category');
GO

-- ============================================================
-- 6. INSERT WEATHER DATA
-- ============================================================
INSERT INTO Weather (event_id, forecast_date, temperature, conditions, humidity, wind_speed, wind_direction, rainfall_mm, weather_source, is_forecast)
VALUES
    -- Comrades Marathon Weather
    (1, '2026-06-20 06:00:00', 12.5, 'Partly Cloudy', 65, 15.0, 'SW', 0.0, 'SAWS', 1),
    (1, '2026-06-21 06:00:00', 14.0, 'Sunny', 60, 10.0, 'S', 0.0, 'SAWS', 1),
    (1, '2026-06-22 06:00:00', 16.5, 'Clear', 55, 8.0, 'SE', 0.0, 'SAWS', 1),
    
    -- Cape Town Cycle Tour Weather
    (2, '2026-03-07 06:00:00', 18.0, 'Sunny', 70, 20.0, 'SE', 0.0, 'SAWS', 1),
    (2, '2026-03-08 06:00:00', 22.0, 'Sunny', 65, 25.0, 'SE', 0.0, 'SAWS', 1),
    
    -- Actual weather recorded
    (1, '2025-06-21 06:00:00', 13.5, 'Rainy', 80, 12.0, 'SW', 5.2, 'Actual', 0);
GO

-- ============================================================
-- 7. INSERT ROUTE DATA
-- ============================================================
INSERT INTO Route (event_id, route_name, distance_km, elevation_gain, elevation_loss, start_location, finish_location, route_description, water_points, aid_stations, is_active)
VALUES
    -- Comrades Marathon Route
    (1, 'Comrades Classic Route', 89.0, 1200, 1400, 'Pietermaritzburg City Hall', 'Durban Kingsmead Stadium', 
     'Starting in Pietermaritzburg, the route ascends Polly Shortts, through the scenic Valley of a Thousand Hills, before descending into Durban. The route features 5 major climbs including Inchanga and Botha''s Hill.',
     25, 15, 1),
    
    -- Cape Town Cycle Tour Route
    (2, 'Cape Town Peninsula Loop', 109.0, 850, 850, 'Grand Parade, Cape Town', 'Grand Parade, Cape Town', 
     'Iconic route around the Cape Peninsula, passing through Camps Bay, Hout Bay, Chapman''s Peak, Scarborough, and ending back in Cape Town. Features the famous Chapman''s Peak Drive.',
     15, 10, 1),
    
    -- Soweto Marathon Route
    (3, 'Soweto Heritage Route', 42.2, 300, 300, 'FNB Stadium', 'FNB Stadium', 
     'Route takes runners through the historic streets of Soweto, passing landmarks including the Orlando Towers, Vilakazi Street (home to Nelson Mandela), and the Hector Pieterson Museum.',
     12, 8, 1);
GO

-- ============================================================
-- 8. INSERT EVENT MEDIA
-- ============================================================
INSERT INTO EventMedia (event_id, media_type, media_url, description, uploaded_by)
VALUES
    (1, 'Map', 'https://raceday.co.za/media/comrades-2026-route-map.jpg', 'Comrades Marathon 2026 Route Map', 1),
    (1, 'Image', 'https://raceday.co.za/media/comrades-banner.jpg', 'Comrades Marathon Event Banner', 1),
    (2, 'Map', 'https://raceday.co.za/media/ctct-2026-route-map.pdf', 'Cape Town Cycle Tour 2026 Route Map', 2),
    (2, 'Image', 'https://raceday.co.za/media/ctct-start-line.jpg', 'Cape Town Cycle Tour Start Line', 2),
    (3, 'Image', 'https://raceday.co.za/media/soweto-marathon-banner.jpg', 'Soweto Marathon Event Banner', 1);
GO

-- ============================================================
-- 9. INSERT NOTIFICATIONS (Sample)
-- ============================================================
INSERT INTO Notification (user_id, notification_type, title, message, is_read, link_url)
VALUES
    (3, 'Event_Reminder', 'Comrades Marathon Reminder', 'Your Comrades Marathon is in 30 days! Don''t forget to prepare.', 0, '/events/1'),
    (4, 'Payment_Confirm', 'Payment Confirmed', 'Your payment for Comrades Marathon has been confirmed. See you at the start line!', 1, '/enrolments/2'),
    (5, 'Registration', 'Welcome to RaceDay!', 'Welcome Sipho! You''re now registered for the RaceDay platform.', 0, '/dashboard'),
    (3, 'Result', 'Your Result is Ready', 'Your Comrades Marathon result has been published. Check your performance now!', 0, '/results/1');
GO

-- ============================================================
-- ============================================================
-- VERIFICATION QUERIES (For testing the database)
-- ============================================================

-- 1. List all events with organiser names
SELECT 
    e.event_id,
    e.event_name,
    e.event_date,
    u.full_name AS organiser_name,
    e.event_status
FROM [Event] e
INNER JOIN [User] u ON e.organiser_id = u.user_id
ORDER BY e.event_date;

-- 2. Show all categories for the Comrades Marathon
SELECT 
    c.category_name,
    c.distance_km,
    c.entry_fee,
    c.capacity,
    COUNT(en.enrolment_id) AS enrolled_count
FROM Category c
LEFT JOIN Enrolment en ON c.category_id = en.category_id
WHERE c.event_id = 1
GROUP BY c.category_id, c.category_name, c.distance_km, c.entry_fee, c.capacity
ORDER BY c.distance_km;

-- 3. List all participants for an event with their categories
SELECT 
    u.full_name,
    u.email,
    c.category_name,
    en.status,
    en.payment_status,
    en.bib_number
FROM Enrolment en
INNER JOIN [User] u ON en.participant_id = u.user_id
INNER JOIN Category c ON en.category_id = c.category_id
WHERE en.event_id = 1
ORDER BY c.category_name, u.full_name;

-- 4. Show results for Comrades Marathon
SELECT 
    u.full_name,
    c.category_name,
    r.finish_time,
    r.overall_position,
    r.category_position,
    r.pace_per_km,
    r.status
FROM [Result] r
INNER JOIN Enrolment en ON r.enrolment_id = en.enrolment_id
INNER JOIN [User] u ON en.participant_id = u.user_id
INNER JOIN Category c ON en.category_id = c.category_id
WHERE en.event_id = 1
ORDER BY r.overall_position;

-- 5. Check database statistics
SELECT 
    (SELECT COUNT(*) FROM [User]) AS total_users,
    (SELECT COUNT(*) FROM [User] WHERE role = 'Organiser') AS total_organisers,
    (SELECT COUNT(*) FROM [User] WHERE role = 'Participant') AS total_participants,
    (SELECT COUNT(*) FROM [Event]) AS total_events,
    (SELECT COUNT(*) FROM Category) AS total_categories,
    (SELECT COUNT(*) FROM Enrolment) AS total_enrolments,
    (SELECT COUNT(*) FROM [Result]) AS total_results;

-- ============================================================
-- ============================================================
-- CLEANUP SCRIPT (Optional - for testing only)
-- ============================================================
/*
-- To drop all tables (clean database):
DROP TABLE IF EXISTS Notification;
DROP TABLE IF EXISTS EventMedia;
DROP TABLE IF EXISTS Route;
DROP TABLE IF EXISTS Weather;
DROP TABLE IF EXISTS [Result];
DROP TABLE IF EXISTS Enrolment;
DROP TABLE IF EXISTS Category;
DROP TABLE IF EXISTS [Event];
DROP TABLE IF EXISTS [User];
*/

PRINT 'RaceDay Database Schema created and seeded successfully.';
GO