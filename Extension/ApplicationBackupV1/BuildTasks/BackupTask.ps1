[CmdletBinding()]
param()
Trace-VstsEnteringInvocation $MyInvocation

#General Section
    $_sourceMachineName = (Get-VstsInput -Name 'MachineName' -Require)
    $_sourcePath = (Get-VstsInput -Name 'SourcePath')
    $_adminLogin = (Get-VstsInput -Name 'AdminLogin')
    $_adminPassword = (ConvertTo-SecureString -String (Get-VstsInput -Name 'AdminPassword') -AsPlainText -Force)
    $_destinationMachineName = (Get-VstsInput -Name 'DestinationMachineName')
    $_destinationPath = (Get-VstsInput -Name 'DestinationPath' -Require)
#Archive Section
    $_createArchive = (Get-VstsInput -Name 'CreateArchive' -AsBool)
    $_includeRootFolder = (Get-VstsInput -Name 'IncludeRootFolder' -AsBool)
    $_archiveFileName = (Get-VstsInput -Name 'ArchiveFileName')


    Write-Output "Entering Application Backup Task."

    Write-VstsTaskDebug -Message "Paremeters: ==================================================================="
    Write-VstsTaskDebug -Message "MachineName: $($_sourceMachineName)" 
    Write-VstsTaskDebug -Message "SourcePath: $($_sourcePath)"
    Write-VstsTaskDebug -Message "AdminLogin: $($_adminLogin)" 
    Write-VstsTaskDebug -Message "DestinationMachineName: $($_destinationMachineName)"
    Write-VstsTaskDebug -Message "DestinationPath: $($_destinationPath)"
    Write-VstsTaskDebug -Message "CreateArchive: $($_createArchive)"
    Write-VstsTaskDebug -Message "IncludeRootFolder: $($_includeRootFolder)"
    Write-VstsTaskDebug -Message "ArchiveFileName: $($_archiveFileName)"
    Write-VstsTaskDebug -Message "==============================================================================="


    if([string]::IsNullOrWhiteSpace($_destinationMachineName))
    {
        $_destinationMachineName = $_sourceMachineName
    }

try {
    
    $backupJob = {
        param (
            [object]$credential,
            [string]$sourceMachineName,
            [string]$path,
            [string]$destMachine,
            [string]$destPath,
            [bool]$createArchive,
            [string]$archiveFileName,
            [bool]$includeRootFolder
        )

        Write-VstsTaskDebug -Message "Paremeters: ==================================================================="
        Write-VstsTaskDebug -Message "sourceMachineName: $($sourceMachineName)" 
        Write-VstsTaskDebug -Message "path: $($path)"
        Write-VstsTaskDebug -Message "destMachine: $($destMachine)"
        Write-VstsTaskDebug -Message "destPath: $($destPath)"
        Write-VstsTaskDebug -Message "CreateArchive: $($createArchive)"
        Write-VstsTaskDebug -Message "IncludeRootFolder: $($_includeRootFolder)"
        Write-VstsTaskDebug -Message "archiveFileName: $($_archiveFileName)"
        Write-VstsTaskDebug -Message "includeRootFolder: $($includeRootFolder)"
        Write-VstsTaskDebug -Message "==============================================================================="
    
        Write-Output "Start Backup Job..."

        function Get-MachineShare([string]$machine, [string]$targetPath)
        {
            Write-VstsTaskDebug -Message "Entering Get-MachineShare function"
            Write-VstsTaskDebug -Message "machine: $($machine)"
            Write-VstsTaskDebug -Message "targetPath: $($targetPath)"

            if([bool]([uri]$targetPath).IsUnc)
            {
                return $targetPath
            }
            if($machine)
            {
                return [IO.Path]::DirectorySeparatorChar + [IO.Path]::DirectorySeparatorChar + $machine
            }

            return ""
        }

        function Get-DestinationNetworkPath([string]$targetPath, [string]$machineShare, [string]$zipFileName, [bool]$archive)
        {
            Write-VstsTaskDebug -Message "Entering Get-DestinationNetworkPath function"
            Write-VstsTaskDebug -Message "targetPath: $($targetPath)"
            Write-VstsTaskDebug -Message "machineShare: $($machineShare)"
            Write-VstsTaskDebug -Message "zipFileName: $($zipFileName)"
            Write-VstsTaskDebug -Message "archive: $($archive)"

            if(-not $machineShare -and $archive)
            {
                return [io.path]::Combine($targetPath, $zipFileName)
            }

            if(-not $machineShare)
            {
                return $targetPath
            }

            $targetSpecificPath = Replace-First $targetPath ":" '$'
            if($archive)
            {
                return [io.path]::Combine($machineShare, $targetSpecificPath, $zipFileName)
            }
            return [io.path]::Combine($machineShare, $targetSpecificPath)
        
        }

        function Replace-First([string]$text, [string]$search, [string]$replace)
        {
            $pos = $text.IndexOf($search);
            if ($pos -le 0)
            {
                return $text;
            }

            return $text.Substring(0, $pos) + $replace + $text.Substring($pos + $search.Length);
        }
        function Create-DestinationDirectory(
            [string]$path
        )
        {
            $destPath = $path
            $foundParentPath = $false
            $isRoot = $false
    
            Write-Verbose "Creating path to directory: $path"
            while($destPath -and (-not $foundParentPath))
            {
                try
                {
                    New-PSDrive -Name WFCPSDrive -PSProvider FileSystem -Root $destPath -Credential $credential -ErrorAction 'Stop'
                    $foundParentPath = $true
                    Write-Verbose "Found parent path"
                    $relativePath = $path.Substring($destPath.Length)
                    New-Item -ItemType Directory WFCPSDrive:$relativePath -ErrorAction 'Stop' -Force
                    Write-Verbose "Created directory"
                }
                catch 
                {
                    Write-Verbose "Caught exception: $_.Exception.Message"
                    $parentPath = Split-Path -Path $destPath -Parent
                    if(($parentPath.Length -eq 0) -and ($isRoot -eq $false))
                    {
                        $destPath = [IO.Path]::DirectorySeparatorChar + [IO.Path]::DirectorySeparatorChar + ([System.Uri]($destPath)).Host
                        $isRoot = $true
                        Write-Verbose "Check if root path exists: $destPath"
                    }
                    else
                    {
                        $destPath = $parentPath
                        Write-Verbose "Check if parent path exists: $destPath"
                    }
                }
                finally
                {
                    if($foundParentPath -eq $true)
                    {
                        Remove-PSDrive -Name WFCPSDrive
                    }
                }
            }
        }

        Write-Output "Create Network pathes"
        
        $sourceMachineShare = Get-MachineShare -machine $sourceMachineName -targetPath $path
        $sourceNetworkPath = Get-DestinationNetworkPath -targetPath $path -machineShare $sourceMachineShare

        $destMachineShare = Get-MachineShare -machine $destMachine -targetPath $destPath
        $targetNetworkPath = Get-DestinationNetworkPath -targetPath $destPath -machineShare $destMachineShare -zipFileName $archiveFileName -archive $createArchive

        Write-VstsTaskDebug -Message "sourceNetworkPath: $($sourceNetworkPath)"
        Write-VstsTaskDebug -Message "targetNetworkPath: $($targetNetworkPath)"

		Write-VstsTaskDebug -Message "Get name of directory from $($targetNetworkPath)"
        $destinationDirectory = [System.IO.Path]::GetDirectoryName($targetNetworkPath)
		Write-VstsTaskDebug -Message "Test $($destinationDirectory) directory"
#		if(-not (Test-Path -Path $destinationDirectory -Credential $credential))
#		{
#			Write-VstsTaskDebug -Message "$($destinationDirectory) folder does not exist"
			Create-DestinationDirectory -path $destinationDirectory
#		}

        try 
		{
			Write-VstsTaskDebug -Message "Check access for $($destinationDirectory)"
			New-PSDrive -Name "DestDrive" -PSProvider FileSystem -Root $destinationDirectory -Credential $credential -ErrorAction 'Stop'
			Write-VstsTaskDebug -Message "Check access for $($sourceNetworkPath)"
			New-PSDrive -Name "SourcePSDrive" -PSProvider FileSystem -Root $sourceNetworkPath -Credential $credential -ErrorAction 'Stop'
		} catch {
			Write-VstsTaskError -Message (Get-VstsLocString -Key "WFC_FailedToCreatePSDrive" -ArgumentList $destinationDirectory, $($_.Exception.Message)) -ErrCode "WFC_FailedToCreatePSDrive"
			throw
        }
        
        try
		{
            if($createArchive -eq $true)
            {
                Write-Output "Create archive file."

                Add-Type -AssemblyName System.IO.Compression.FileSystem
				Compress-Archive -Path $sourceNetworkPath -DestinationPath $targetNetworkPath -CompressionLevel "Optimal"
            }
            else {
                Write-Output "Copy files and subfolders."
                Robocopy $sourceNetworkPath $targetNetworkPath /E
            }
        }
        finally
        {
            if ($machineShare)
            {
                $remoteSharePsDrive = Get-PSDrive -Name 'DestDrive' -ErrorAction 'SilentlyContinue'
                if ($remoteSharePsDrive -ne $null)
                {
                    $remoteSharePath = $remoteSharePsDrive.Root
                    Write-Verbose "Attempting to remove PSDrive 'DestDrive'"
                    Remove-PSDrive -Name 'DestDrive' -Force
                    Write-Verbose "RemoteSharePath: $remoteSharePath"
                    Try-CleanupPSDrive -Path $remoteSharePath
                }
                $remote1SharePsDrive = Get-PSDrive -Name 'SourcePSDrive' -ErrorAction 'SilentlyContinue'
                if ($remote1SharePsDrive -ne $null)
                {
                    $remote1SharePsDrive = $remote1SharePsDrive.Root
                    Write-Verbose "Attempting to remove PSDrive 'WFCPSDrive'"
                    Remove-PSDrive -Name 'remote1SharePsDrive' -Force
                    Write-Verbose "RemoteSharePath: $remote1SharePsDrive"
                    Try-CleanupPSDrive -Path $remote1SharePsDrive
                }
            }
        }

    }
    
    Write-Output "Create powershell credential."
    $psSourceCredential = New-Object System.Management.Automation.PSCredential($_adminLogin , $_adminPassword);

    $invokeCommandSplat = @{
        ScriptBlock = $backupJob
    }

    Write-Output "Invoke Backup Job"
    Invoke-Command @invokeCommandSplat -ArgumentList $psSourceCredential, $_sourceMachineName, $_sourcePath, $_destinationMachineName, $_destinationPath, $_createArchive, $_archiveFileName, $_includeRootFolder
}
catch {
    Write-VstsTaskError -Message $_.Exception.Message
    Write-VstsSetResult -Result "Failed" -Message $_.Exception.Message
}
finally {
    Trace-VstsLeavingInvocation $MyInvocation
}
