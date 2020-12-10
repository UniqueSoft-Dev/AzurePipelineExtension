[CmdletBinding()]
param()
Trace-VstsEnteringInvocation $MyInvocation

    $_backupType = (Get-VstsInput -Name 'BackupType' -Require)
    $_sourceMachineName = (Get-VstsInput -Name 'MachineName' -Require)
    $_sourcePath = (Get-VstsInput -Name 'SourcePath')
    $_sourceWebsiteName = (Get-VstsInput -Name 'SourceWebsiteName')
    $_adminLogin = (Get-VstsInput -Name 'AdminLogin')
    $_sourceAdminPassword = (ConvertTo-SecureString -String (Get-VstsInput -Name 'AdminPassword') -AsPlainText -Force)
    $_createZip = (Get-VstsInput -Name 'CreateZip' -AsBool)
    $_zipFileName = (Get-VstsInput -Name 'ZipFileName')

try {
    $sourceScriptBlock = {
        $backupType = $args[0],
        $machineName = $args[1]
        $path = $args[2],
        $site = $args[3],
        $createZip = $args[4],
        $fileName = $args[5],
        $destPath = $args[6]

        function Get-MachineShare([string]$machine, [string]$targetPath)
        {
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

        function Get-DestinationNetworkPath([string]$targetPath, [string]$machineShare, [string]$zipFileName)
        {
            if(-not $machineShare)
            {
                return [io.path]::Combine($targetPath, $zipFileName)
            }

            $targetSpecificPath = Replace-First $targetPath ":" '$'    
            return [io.path]::Combine($machineShare, $targetSpecificPath, $zipFileName)    
        
        }

        
        $machineShare = Get-MachineShare -machine $fqdn -targetPath $destPath
        $targetNetworkPath = Get-DestinationNetworkPath -targetPath $destPath -machineShare $machineShare -zipFileName $fileName

        

        if (-not $path -and $backupType -eq "Website") {
            $path = (Get-Website $site | Select-Object).PhysicalPath
        }
        
        if ($createZip -eq $true) {
            Add-Type -AssemblyName System.IO.Compression.FileSystem

            $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
            [System.IO.Compression.ZipFile]::CreateFromDirectory($path, $targetNetworkPath, $compressionLevel, $false)
        }
        else {
            Robocopy $path $targetNetworkPath /E 
        }
    }
    
    $psSourceCredential = New-Object System.Management.Automation.PSCredential($_adminLogin , $_sourceAdminPassword);

    $invokeCommandSplat = @{
        ScriptBlock = $sourceScriptBlock
    }

    if ($credential)
    {
        $invokeCommandSplat.Credential = $psSourceCredential
        $invokeCommandSplat.ComputerName = $_sourceMachineName
    }
    
    Invoke-Command @invokeCommandSplat -ArgumentList $_backupType, $_sourceMachineName, $_sourcePath, $_sourceWebsiteName, $_createZip, $_zipFileName, $_destinationPath
}
finally {
    Trace-VstsLeavingInvocation $MyInvocation
}
