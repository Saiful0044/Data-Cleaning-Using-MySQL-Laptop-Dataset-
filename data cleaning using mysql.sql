SELECT * FROM laptop;
-- create backup of the Database
CREATE TABLE laptop_backup LIKE laptop; 
INSERT INTO laptop_backup SELECT * FROM laptop;

SELECT * FROM laptop;

-- Check the size of the dataset
SELECT DATA_LENGTH/1024 FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'data_cleaning'
AND TABLE_NAME = 'laptop';

--  Drop Null Values
CREATE TEMPORARY TABLE temp_df
SELECT `index` FROM laptop
WHERE Company IS NULL AND TypeName IS NULL AND Inches IS NULL
AND ScreenResolution IS NULL AND Cpu IS NULL AND Ram IS NULL
AND Memory IS NULL AND Gpu IS NULL AND OpSys IS NULL AND
WEIGHT IS NULL AND Price IS NULL;

DELETE FROM laptop
WHERE `index` IN ( SELECT * FROM temp_df);

-- Drop duplicate
CREATE TEMPORARY TABLE temp_dupliicate
SELECT MIN(`index`) AS 'index' FROM laptop
GROUP BY Company,TypeName,Inches,ScreenResolution,Cpu,Ram,
Memory,Gpu,OpSys,Weight,Price
HAVING COUNT(*)>1;

SELECT * FROM temp_dupliicate;
DELETE FROM laptop WHERE `index` IN (SELECT `index` FROM temp_dupliicate);

SELECT MIN(`index`) AS 'index' FROM laptop
GROUP BY Company,TypeName,Inches,ScreenResolution,Cpu,Ram,
Memory,Gpu,OpSys,Weight,Price
HAVING COUNT(*)>1;

-- Convert the `inches` column datatype to decimal 
ALTER TABLE laptop MODIFY COLUMN Inches DECIMAL(10,2);


-- Clean the RAM  like GB,column and change it to integer

SELECT Ram, REPLACE(Ram,'GB','') FROM laptop;
UPDATE laptop
SET Ram = REPLACE(Ram,'GB','');

ALTER TABLE laptop MODIFY COLUMN Ram INTEGER;

-- Split the weight '1.37kg' to '1.37' and Convert it to float
UPDATE laptop 
SET Weight = REPLACE(Weight,'kg','');

-- we have some incorrect vlaues so we use the this commad to replace this  type of values
UPDATE laptop SET Weight = 0
WHERE Weight = '?';

-- now convert this column datatype 
ALTER TABLE laptop MODIFY COLUMN  Weight DECIMAL(10,2);

-- Price column in double formate datatype and float values so covert it to Integer 
UPDATE laptop SET Price = ROUND(Price);
SELECT * FROM laptop;

-- OpSys column have incorrect values so convert it to proper values
-- mac
-- windows
-- linux
-- no os
-- Android chrome(others)
SELECT DISTINCT(OpSys) FROM laptop;
SELECT OpSys,
CASE 
	WHEN OpSys LIKE '%mac%' THEN 'macos'
    WHEN OpSys LIKE '%windows%' THEN 'windows'
    WHEN OpSys LIKE '%linux%' THEN 'linux'
    WHEN OpSys LIKE '%No OS%' THEN 'N/A'
    ELSE 'other' 
END AS 'os_brand'
FROM laptop;
-- Then update this kind of values in our table
UPDATE laptop
SET OpSys = CASE 
	WHEN OpSys LIKE '%mac%' THEN 'macos'
    WHEN OpSys LIKE '%windows%' THEN 'windows'
    WHEN OpSys LIKE '%linux%' THEN 'linux'
    WHEN OpSys LIKE '%No OS%' THEN 'N/A'
    ELSE 'other' 
END;

-- In the cpu column have three pieces of infomartion such as 'cpu_brand','cpu_name','cpu_speed' so here is need to separated this info-
ALTER TABLE laptop
ADD COLUMN cpu_brand VARCHAR(255) AFTER Cpu,
ADD COLUMN cpu_name VARCHAR(255) AFTER cpu_brand,
ADD COLUMN cpu_speed VARCHAR(255) AFTER cpu_name;

SELECT Cpu, SUBSTRING_INDEX(Cpu,' ',1) FROM laptop;

-- UPDATE cpu_brand
UPDATE laptop
SET cpu_brand = SUBSTRING_INDEX(Cpu,' ',1);

-- update cpu_name
SELECT Cpu, REPLACE(Cpu, cpu_brand,'') FROM laptop;
UPDATE laptop
SET cpu_name = 	REPLACE(Cpu, cpu_brand,'');

-- update cpu_spedd
SELECT REPLACE(SUBSTRING_INDEX(cpu_name,' ',-1),'GHz','') FROM laptop;

UPDATE laptop
SET cpu_speed = REPLACE(SUBSTRING_INDEX(cpu,' ',-1),'GHz','');
ALTER TABLE laptop MODIFY COLUMN cpu_speed DECIMAL(10,2);

-- Delete the Cpu column 
ALTER TABLE laptop DROP COLUMN Cpu;

-- Gpu Column have mixed values like 'Gpu brand' and 'Gpu name' here we are separated each other
ALTER TABLE laptop
ADD COLUMN gpu_brand VARCHAR(255) AFTER Gpu,
ADD COLUMN gpu_name VARCHAR(255) AFTER gpu_brand;

SELECT SUBSTRING_INDEX(Gpu,' ',1) FROM laptop;
-- update the gpu_brand column
UPDATE laptop
SET gpu_brand = SUBSTRING_INDEX(Gpu,' ' ,1);

-- update the gpu_name column
SELECT REPLACE(Gpu,gpu_brand,'') FROM laptop;
UPDATE laptop
SET gpu_name = REPLACE(Gpu, gpu_brand,'');

-- delete the Gpu column
ALTER TABLE laptop DROP COLUMN Gpu;

-- ScreenResolution Column
-- ScreenResolution column have 3 pieces of information 
-- 1. is screen height
-- 2. is  screen weight 
-- 3. is Touchscreen 
ALTER TABLE laptop
ADD COLUMN resolution_height INTEGER AFTER ScreenResolution,
ADD COLUMN resolution_weight INTEGER AFTER resolution_height,
ADD COLUMN touchscreen INTEGER AFTER resolution_weight;

SELECT 
SUBSTRING_INDEX(SUBSTRING_INDEX(ScreenResolution,' ',-1),'x',1),
SUBSTRING_INDEX(SUBSTRING_INDEX(ScreenResolution,' ',-1),'x',-1)
FROM laptop;

-- update the resolution_height and resolution_weight
UPDATE laptop
SET resolution_weight = SUBSTRING_INDEX(SUBSTRING_INDEX(ScreenResolution,' ',-1),'x',1),
	resolution_height = SUBSTRING_INDEX(SUBSTRING_INDEX(ScreenResolution,' ',-1),'x',-1);

SELECT * FROM laptop;
-- update the touchscreen
SELECT * FROM laptop
WHERE ScreenResolution LIKE "%Touch%";

UPDATE laptop
SET touchscreen = ScreenResolution LIKE "%Touch%";

-- ADD COLUMN 
ALTER TABLE laptop 
ADD COLUMN ips INTEGER AFTER touchscreen;

SELECT * FROM laptop
WHERE ScreenResolution LIKE "%IPS%";

-- update the ips column
UPDATE laptop
SET ips = ScreenResolution LIKE "%IPS%";

-- delete the ScreenResolution column
ALTER TABLE laptop DROP COLUMN ScreenResolution;

-- Memory column also contain many information
-- SSD, Flash Storage, HDD, Hybrid
-- Create 'memory_type', primary_storage,secondary_storage  Column 
-- ?
ALTER TABLE laptop
ADD COLUMN memory_type VARCHAR(255) AFTER Memory,
ADD COLUMN primary_storage INTEGER AFTER memory_type,
ADD COLUMN secondary_storage INTEGER AFTER primary_storage;


SELECT distinct(Memory) FROM laptop;
SELECT Memory,
CASE
	WHEN Memory LIKE '%SSD%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
    WHEN Memory LIKE '%Flash Storage%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
    WHEN Memory LIKE '%SSD%' AND Memory LIKE '%Hybrid%' THEN 'Hybrid'
    WHEN Memory LIKE '%Hybrid%' THEN 'Hybrid'
    WHEN Memory LIKE '%SSD%' THEN 'SSD'
    WHEN Memory LIKE '%HDD%' THEN 'HDD'
    WHEN Memory LIKE '%Flash Storage%' THEN 'Flash Storage'
    ELSE NULL
END AS Memory_type
FROM laptop;

-- update the memory type column
UPDATE laptop
SET Memory_type = CASE
	WHEN Memory LIKE '%SSD%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
    WHEN Memory LIKE '%Flash Storage%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
    WHEN Memory LIKE '%SSD%' AND Memory LIKE '%Hybrid%' THEN 'Hybrid'
    WHEN Memory LIKE '%Hybrid%' THEN 'Hybrid'
    WHEN Memory LIKE '%SSD%' THEN 'SSD'
    WHEN Memory LIKE '%HDD%' THEN 'HDD'
    WHEN Memory LIKE '%Flash Storage%' THEN 'Flash Storage'
    ELSE NULL
END;

-- check the primary and secondary storage
SELECT 
Memory,
REGEXP_SUBSTR(SUBSTRING_INDEX(Memory,'+',1),'[0-9]+'),
CASE 
	WHEN Memory LIKE '%+%' THEN
	REGEXP_SUBSTR(SUBSTRING_INDEX(Memory,'+',-1),'[0-9]+')
    ELSE 0
END
FROM laptop;

-- update the primary and secondary storage column
UPDATE laptop
SET primary_storage = REGEXP_SUBSTR(SUBSTRING_INDEX(Memory,'+',1),'[0-9]+'),
	secondary_storage = CASE 
							WHEN Memory LIKE '%+%' THEN
							REGEXP_SUBSTR(SUBSTRING_INDEX(Memory,'+',-1),'[0-9]+')
							ELSE 0
						END;
                        
SELECT primary_storage,
CASE 
	WHEN primary_storage <=2 THEN primary_storage*1024 ELSE primary_storage END ,
secondary_storage,
CASE 
	WHEN secondary_storage <= 2 THEN secondary_storage*1024 ELSE secondary_storage END
 FROM laptop;

-- update the primary_storage and secondary_storage column because some value 1TB
 UPDATE laptop
 SET primary_storage = CASE WHEN primary_storage <=2 THEN primary_storage*1024 ELSE primary_storage END,
	secondary_storage = CASE WHEN secondary_storage <= 2 THEN secondary_storage*1024 ELSE secondary_storage END;
 
SELECT * FROM laptop;
 
 
 -- Now the drop column of Memory;
 ALTER TABLE laptop DROP COLUMN Memory;
 
 SELECT * FROM laptop;
 
SELECT DATA_LENGTH/1024 FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'data_cleaning'
AND TABLE_NAME = 'laptop';

SELECT * FROM laptop;










