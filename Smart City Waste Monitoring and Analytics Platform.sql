DROP DATABASE IF EXISTS WasteAnalyticsProject;
CREATE DATABASE WasteAnalyticsProject;
USE WasteAnalyticsProject;
SHOW DATABASES;
CREATE TABLE CityZone (
    zone_id INT PRIMARY KEY AUTO_INCREMENT,
    zone_name VARCHAR(100),
    city VARCHAR(100)
);

CREATE TABLE SmartBin (
    bin_id INT PRIMARY KEY AUTO_INCREMENT,
    zone_id INT,
    bin_type VARCHAR(50),
    capacity_kg INT,
    current_fill_kg INT,
    status VARCHAR(50),
    FOREIGN KEY (zone_id) REFERENCES CityZone(zone_id)
);

CREATE TABLE GarbageTruck (
    truck_id INT PRIMARY KEY AUTO_INCREMENT,
    truck_number VARCHAR(50),
    driver_name VARCHAR(100),
    capacity_kg INT
);

CREATE TABLE PickupSchedule (
    schedule_id INT PRIMARY KEY AUTO_INCREMENT,
    bin_id INT,
    truck_id INT,
    pickup_date DATE,
    waste_collected_kg INT,
    pickup_status VARCHAR(50),
    FOREIGN KEY (bin_id) REFERENCES SmartBin(bin_id),
    FOREIGN KEY (truck_id) REFERENCES GarbageTruck(truck_id)
);

CREATE TABLE CitizenComplaint (
    complaint_id INT PRIMARY KEY AUTO_INCREMENT,
    zone_id INT,
    citizen_name VARCHAR(100),
    complaint_text VARCHAR(255),
    complaint_date DATE,
    status VARCHAR(50),
    FOREIGN KEY (zone_id) REFERENCES CityZone(zone_id)
);
SHOW TABLES;
USE WasteAnalyticsProject;

INSERT INTO CityZone (zone_name, city) VALUES
('Tambaram', 'Chennai'),
('Chrompet', 'Chennai'),
('Guindy', 'Chennai'),
('Velachery', 'Chennai');

INSERT INTO SmartBin (zone_id, bin_type, capacity_kg, current_fill_kg, status) VALUES
(1, 'Organic', 100, 90, 'Almost Full'),
(1, 'Plastic', 120, 60, 'Normal'),
(2, 'Organic', 100, 100, 'Full'),
(2, 'E-Waste', 80, 40, 'Normal'),
(3, 'Plastic', 150, 130, 'Almost Full'),
(4, 'Organic', 100, 30, 'Normal');

INSERT INTO GarbageTruck (truck_number, driver_name, capacity_kg) VALUES
('TN11AB1234', 'Ravi', 500),
('TN11CD5678', 'Kumar', 700),
('TN22EF9012', 'Suresh', 600);

INSERT INTO PickupSchedule 
(bin_id, truck_id, pickup_date, waste_collected_kg, pickup_status)
VALUES
(1, 1, '2026-06-01', 90, 'Collected'),
(2, 1, '2026-06-01', 60, 'Collected'),
(3, 2, '2026-06-02', 100, 'Collected'),
(4, 3, '2026-06-02', 40, 'Collected'),
(5, 2, '2026-06-03', 130, 'Pending');

INSERT INTO CitizenComplaint 
(zone_id, citizen_name, complaint_text, complaint_date, status)
VALUES
(1, 'Arun', 'Bin is overflowing near main road', '2026-06-01', 'Pending'),
(2, 'Priya', 'Bad smell due to uncollected waste', '2026-06-01', 'Resolved'),
(3, 'Karthik', 'Plastic waste not collected', '2026-06-02', 'Pending');

CREATE VIEW BinFillReport AS
SELECT 
    b.bin_id,
    z.zone_name,
    b.bin_type,
    b.capacity_kg,
    b.current_fill_kg,
    ROUND((b.current_fill_kg / b.capacity_kg) * 100, 2) AS fill_percentage,
    b.status
FROM SmartBin b
JOIN CityZone z ON b.zone_id = z.zone_id;

DELIMITER //

CREATE TRIGGER UpdateSmartBinStatus
BEFORE UPDATE ON SmartBin
FOR EACH ROW
BEGIN
    IF NEW.current_fill_kg >= NEW.capacity_kg THEN
        SET NEW.status = 'Full';
    ELSEIF NEW.current_fill_kg >= NEW.capacity_kg * 0.8 THEN
        SET NEW.status = 'Almost Full';
    ELSE
        SET NEW.status = 'Normal';
    END IF;
END //

CREATE PROCEDURE GetZoneWasteReport(IN zoneName VARCHAR(100))
BEGIN
    SELECT 
        z.zone_name,
        b.bin_type,
        SUM(p.waste_collected_kg) AS total_collected
    FROM PickupSchedule p
    JOIN SmartBin b ON p.bin_id = b.bin_id
    JOIN CityZone z ON b.zone_id = z.zone_id
    WHERE z.zone_name = zoneName
    GROUP BY z.zone_name, b.bin_type;
END //

DELIMITER ;

SELECT * FROM CityZone;
SELECT * FROM SmartBin;
SELECT * FROM GarbageTruck;
SELECT * FROM PickupSchedule;
SELECT * FROM CitizenComplaint;
SELECT * FROM BinFillReport;

CALL GetZoneWasteReport('Tambaram');
UPDATE SmartBin
SET current_fill_kg = 110
WHERE bin_id = 2;

SELECT * FROM SmartBin;
SELECT * 
FROM SmartBin
WHERE status = 'Full';
SELECT 
    bin_id,
    bin_type,
    capacity_kg,
    current_fill_kg,
    ROUND((current_fill_kg / capacity_kg) * 100, 2) AS fill_percentage
FROM SmartBin
WHERE (current_fill_kg / capacity_kg) * 100 >= 80;
SELECT 
    z.zone_name,
    SUM(p.waste_collected_kg) AS total_waste_collected
FROM PickupSchedule p
JOIN SmartBin b ON p.bin_id = b.bin_id
JOIN CityZone z ON b.zone_id = z.zone_id
WHERE p.pickup_status = 'Collected'
GROUP BY z.zone_name;
SELECT 
    b.bin_type,
    SUM(p.waste_collected_kg) AS total_waste
FROM PickupSchedule p
JOIN SmartBin b ON p.bin_id = b.bin_id
WHERE p.pickup_status = 'Collected'
GROUP BY b.bin_type;
SELECT 
    p.schedule_id,
    z.zone_name,
    b.bin_type,
    p.pickup_date,
    p.pickup_status
FROM PickupSchedule p
JOIN SmartBin b ON p.bin_id = b.bin_id
JOIN CityZone z ON b.zone_id = z.zone_id
WHERE p.pickup_status = 'Pending';
SELECT 
    z.zone_name,
    COUNT(c.complaint_id) AS total_complaints
FROM CitizenComplaint c
JOIN CityZone z ON c.zone_id = z.zone_id
GROUP BY z.zone_name
ORDER BY total_complaints DESC;


