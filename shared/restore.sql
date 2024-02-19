SET NOCOUNT ON;

-- Capture the file list information from the database backup file
DECLARE @FileListTable TABLE (
  LogicalName NVARCHAR(128),
  PhysicalName NVARCHAR(260),
  [Type] CHAR(1),
  FileGroupName NVARCHAR(128),
  Size NUMERIC(20,  0),
  MaxSize NUMERIC(20,  0),
  FileID BIGINT,
  CreateLSN NVARCHAR(255),
  DropLSN NVARCHAR(255),
  UniqueID NVARCHAR(255),
  ReadOnlyLSN NVARCHAR(255),
  ReadWriteLSN NVARCHAR(255),
  BackupSizeInBytes BIGINT,
  SourceBlockSize INT,
  FileGroupID INT,
  LogGroupGUID NVARCHAR(255),
  DifferentialBaseLSN NVARCHAR(255),
  DifferentialBaseGUID NVARCHAR(255),
  IsReadOnly BIT,
  IsPresent BIT,
  TDEThumbprint NVARCHAR(255),
  SnapshotURL NVARCHAR(360)
)
INSERT INTO @FileListTable
EXEC (
  'RESTORE FILELISTONLY FROM DISK=''${BACKUP_FILE}'''
)

-- Construct the RESTORE DATABASE command dynamically
DECLARE @RestoreCommand NVARCHAR(MAX);
SET @RestoreCommand = 'RESTORE DATABASE [${DATABASE_NAME}] FROM DISK = ''${BACKUP_FILE}'' WITH REPLACE, RECOVERY, STATS =  10';
DECLARE @FileList NVARCHAR(MAX) = '';
DECLARE @FileCursor CURSOR;
DECLARE @LogicalName NVARCHAR(128), @PhysicalName NVARCHAR(260), @FileType CHAR(1);

SET @FileCursor = CURSOR FOR
    SELECT LogicalName, PhysicalName, Type FROM @FileListTable;

OPEN @FileCursor;
FETCH NEXT FROM @FileCursor INTO @LogicalName, @PhysicalName, @FileType;

WHILE @@FETCH_STATUS =  0
BEGIN
    IF @FileType = 'D'
      SET @PhysicalName = '/var/opt/mssql/data/' + @LogicalName + '.mdf';
    ELSE IF @FileType = 'L'
      SET @PhysicalName = '/var/opt/mssql/data/' + @LogicalName + '.ldf';

    SET @FileList = @FileList + ', MOVE ''' + @LogicalName + ''' TO ''' + @PhysicalName + '''';

    FETCH NEXT FROM @FileCursor INTO @LogicalName, @PhysicalName, @FileType;
END

CLOSE @FileCursor;
DEALLOCATE @FileCursor;

-- Execute the RESTORE DATABASE command
EXEC (@RestoreCommand + @FileList);
