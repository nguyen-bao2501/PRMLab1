-- Widen only the legacy three-value attendance status constraint.
-- No attendance/session rows are changed. Re-running this migration is safe.
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @table nvarchar(520), @constraint sysname, @definition nvarchar(max), @normalized nvarchar(max), @sql nvarchar(max);
DECLARE status_constraints CURSOR LOCAL FAST_FORWARD FOR
 SELECT QUOTENAME(OBJECT_SCHEMA_NAME(parent_object_id)) + '.' + QUOTENAME(OBJECT_NAME(parent_object_id)), name, definition
 FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID('sessions');
OPEN status_constraints;
FETCH NEXT FROM status_constraints INTO @table, @constraint, @definition;
WHILE @@FETCH_STATUS = 0
BEGIN
 SET @normalized = LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@definition, '[',''), ']',''), '(' ,''), ')',''), ' ',''), CHAR(10),''), CHAR(13),''));
 IF @normalized IN (
  'status=''cancelled''orstatus=''closed''orstatus=''open''',
  'status=''cancelled''orstatus=''open''orstatus=''closed''',
  'status=''closed''orstatus=''cancelled''orstatus=''open''',
  'status=''closed''orstatus=''open''orstatus=''cancelled''',
  'status=''open''orstatus=''closed''orstatus=''cancelled''',
  'status=''open''orstatus=''cancelled''orstatus=''closed''')
 BEGIN
  SET @sql = N'ALTER TABLE ' + @table + N' DROP CONSTRAINT ' + QUOTENAME(@constraint) + N'; ALTER TABLE ' + @table
   + N' WITH CHECK ADD CONSTRAINT ' + QUOTENAME(@constraint) + N' CHECK ([status] IN (''SCHEDULED'',''OPEN'',''CLOSED'',''CANCELLED''));';
  EXEC sp_executesql @sql;
 END;
 FETCH NEXT FROM status_constraints INTO @table, @constraint, @definition;
END;
CLOSE status_constraints;
DEALLOCATE status_constraints;
COMMIT TRANSACTION;
