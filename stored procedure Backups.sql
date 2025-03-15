CREATE PROCEDURE BackupDatabase
    @DatabaseName NVARCHAR(100),
    @BackupType NVARCHAR(20)
AS
BEGIN
    DECLARE @BackupPath NVARCHAR(500)
    DECLARE @BackupFileName NVARCHAR(500)
    DECLARE @BackupCommand NVARCHAR(MAX)
    DECLARE @FolderPath NVARCHAR(500)
    DECLARE @DateSuffix NVARCHAR(50)
    DECLARE @CreateFolderCmd NVARCHAR(500)

    -- Validar si la base de datos existe
    IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = @DatabaseName)
    BEGIN
        RAISERROR('La base de datos especificada no existe.', 16, 1)
        RETURN
    END
    
    -- Definir la ruta base de backups
    SET @BackupPath = 'C:\Backups\' + @DatabaseName + '\'

    -- Crear la carpeta principal si no existe
    SET @CreateFolderCmd = 'IF NOT EXIST "' + @BackupPath + '" mkdir "' + @BackupPath + '"'
    EXEC xp_cmdshell @CreateFolderCmd

    -- Generar timestamp para el nombre del archivo
    SET @DateSuffix = FORMAT(GETDATE(), 'yyyyMMdd_HHmmss')

    -- Determinar la subcarpeta según el tipo de backup
    IF @BackupType = 'FULL'
        SET @FolderPath = @BackupPath + 'Full\'
    ELSE IF @BackupType = 'DIFFERENTIAL'
        SET @FolderPath = @BackupPath + 'Differential\'
    ELSE IF @BackupType = 'LOG'
        SET @FolderPath = @BackupPath + 'Log\'
    ELSE
    BEGIN
        RAISERROR('Tipo de backup inválido. Use FULL, DIFFERENTIAL o LOG.', 16, 1)
        RETURN
    END
    
    -- Crear la carpeta del tipo de backup si no existe
    SET @CreateFolderCmd = 'IF NOT EXIST "' + @FolderPath + '" mkdir "' + @FolderPath + '"'
    EXEC xp_cmdshell @CreateFolderCmd

    -- Definir el nombre del archivo de backup
    SET @BackupFileName = @FolderPath + @DatabaseName + '_' + @BackupType + '_' + @DateSuffix + '.bak'

    -- Construir el comando de backup
    IF @BackupType = 'FULL'
        SET @BackupCommand = 'BACKUP DATABASE [' + @DatabaseName + '] TO DISK = ''' + @BackupFileName + ''' WITH FORMAT, INIT, NAME = ''Full Backup of ' + @DatabaseName + ''''
    ELSE IF @BackupType = 'DIFFERENTIAL'
        SET @BackupCommand = 'BACKUP DATABASE [' + @DatabaseName + '] TO DISK = ''' + @BackupFileName + ''' WITH DIFFERENTIAL, INIT, NAME = ''Differential Backup of ' + @DatabaseName + ''''
    ELSE IF @BackupType = 'LOG'
        SET @BackupCommand = 'BACKUP LOG [' + @DatabaseName + '] TO DISK = ''' + @BackupFileName + ''' WITH INIT, NAME = ''Transaction Log Backup of ' + @DatabaseName + ''''

    -- Ejecutar el comando de backup
    EXEC sp_executesql @BackupCommand
END





EXEC BackupDatabase @DatabaseName = 'SolucioneDB', @BackupType = 'FULL';
EXEC BackupDatabase @DatabaseName = 'SolucioneDB', @BackupType = 'DIFFERENTIAL';
EXEC BackupDatabase @DatabaseName = 'SolucioneDB', @BackupType = 'LOG';
