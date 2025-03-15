# Procedimiento Almacenado para Backups en SQL Server

![SQL Server](https://img.shields.io/badge/Microsoft-SQL_Server-CC2927?logo=microsoft-sql-server&logoColor=white)
![GitHub](https://img.shields.io/badge/GitHub-Repository-brightgreen?logo=github)

Este repositorio contiene un procedimiento almacenado en SQL Server para realizar backups automáticos de bases de datos. El procedimiento organiza los backups en carpetas específicas según el tipo de respaldo (FULL, DIFFERENTIAL, LOG) y genera nombres de archivos únicos utilizando timestamps para evitar sobrescrituras.

---

## 🔧 Características Principales

- **🌟 Automatización**: Genera backups de manera automática.
- **📂 Organización**: Organiza los archivos en una estructura de carpetas clara.
- **❌ Evita Sobrescrituras**: Genera nombres de archivos con timestamps para evitar sobrescribir backups anteriores.
- **🔒 Validación**: Verifica que la base de datos exista antes de ejecutar el respaldo.
- **🛠️ Facilidad de Recuperación**: Mantiene los archivos bien estructurados para una recuperación sencilla.

---

## 🛁 Estructura de Almacenamiento

Los backups se guardan en la siguiente estructura de carpetas:

```plaintext
C:\Backups\<DatabaseName>\Full\
C:\Backups\<DatabaseName>\Differential\
C:\Backups\<DatabaseName>\Log\
```

Cada archivo de backup se nombra con un timestamp para evitar sobrescribir archivos anteriores. Ejemplo:

```plaintext
C:\Backups\VentasDB\Full\VentasDB_FULL_20250314_120000.bak
```

---

## 📝 Implementación del Procedimiento Almacenado

El siguiente código SQL crea el procedimiento almacenado `BackupDatabase`:

```sql
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

```

---

## 🔄 Uso del Procedimiento

Para ejecutar un backup, llama al procedimiento `BackupDatabase` con los parámetros adecuados:

### 📂 Backup Completo (FULL)
```sql
EXEC BackupDatabase @DatabaseName = 'VentasDB', @BackupType = 'FULL';
```

### 🔄 Backup Diferencial (DIFFERENTIAL)
```sql
EXEC BackupDatabase @DatabaseName = 'VentasDB', @BackupType = 'DIFFERENTIAL';
```

### 🔒 Backup del Log de Transacciones (LOG)
```sql
EXEC BackupDatabase @DatabaseName = 'VentasDB', @BackupType = 'LOG';
```

---

## 🔧 Pruebas Realizadas

✅ **Verificación de creación de carpetas**: Se ejecutaron backups de distintas bases de datos y se confirmó la generación de directorios correctos.

✅ **Ejecución con diferentes tipos de backup**: Se probó con FULL, DIFFERENTIAL y LOG, validando que se generaran correctamente.

✅ **Generación de archivos con timestamps**: Se verificó que los nombres no se repiten y reflejan la fecha y hora exacta.

✅ **Validación de errores**: Se intentó hacer backup de una base de datos inexistente, recibiendo el mensaje de error correspondiente.

---

## 🎮 Conclusiones

Este procedimiento almacenado proporciona una solución automatizada y confiable para la gestión de backups en SQL Server. Permite mantener la información segura, organizada y fácil de recuperar en caso de necesidad. Con su implementación, se reducen errores manuales y se optimiza la administración de bases de datos.

---





