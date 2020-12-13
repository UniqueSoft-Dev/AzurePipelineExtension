# Application backup Task
### Owerview
This little tool can help you automatically back up your application files before the release process updates the files.

***
### Parameters include

**Application Server** - Name or IP of the server where the files are located.

**Source Folder** - The source folder or UNC path that the copy pattern(s) will be run from.

**Admin Login** - Administrator login for machines.

**Admin Password** - Password for administrator login for machines. It can accept variable defined in Release definitions as '$(passwordVariable)'. You may mark variable type as 'secret' to secure it.

**Backup Server** - Name or IP of the server to which the backup should be copied. If empty that the 'Target Folder' is UNC path or it is on the 'Application Server'.

**Target Folder** - Target folder or UNC path files will copy to. You can use [variables](https://go.microsoft.com/fwlink/?LinkID=550988). Example: $(Build.BuildNumber)

**Compress Files** - If this option is selected, then a zip file will be created in the destination folder.

**Include root folder** - If this option is selected, then include folder to the archive file.

**Archive file to create** - Specify the name of the archive file to create. You can use [variables](https://go.microsoft.com/fwlink/?LinkID=550988). For example, to create Backup_$(Build.BuildNumber).zip.
