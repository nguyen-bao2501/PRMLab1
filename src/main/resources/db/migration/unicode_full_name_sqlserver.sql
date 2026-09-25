-- Run once on existing SQL Server databases before re-importing Vietnamese names.
IF COL_LENGTH('users', 'full_name') IS NOT NULL
   AND EXISTS (
       SELECT 1
       FROM sys.columns
       WHERE object_id = OBJECT_ID('users')
         AND name = 'full_name'
         AND system_type_id = 167 -- varchar
   )
BEGIN
    ALTER TABLE users ALTER COLUMN full_name NVARCHAR(255) NULL;
END;
