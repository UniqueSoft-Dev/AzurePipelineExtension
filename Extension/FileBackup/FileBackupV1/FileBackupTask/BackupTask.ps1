param
(
    [Parameter()]
    [string]
    $_backupType = (Get-VstsInput -Name 'BackupType' -Require),
    [Parameter()]
    [string]
    $_sourceMachineName = (Get-VstsInput -Name 'SourceMachineName' -Require),
    [Parameter()]
    [string]
    $_sourcePath = (Get-VstsInput -Name 'SourcePath'),
    [Parameter()]
    [string]
    $_sourceWebsiteName = (Get-VstsInput -Name 'SourceWebsiteName'),
    [Parameter()]
    [string]
    $_sourceAdminLogin = (Get-VstsInput -Name 'SourceAdminLogin'),
    [Parameter()]
    [string]
    $_sourceAdminPassword = (Get-VstsInput -Name 'SourceAdminPassword'),
    [Parameter()]
    [string]
    $_destinationMachineName = (Get-VstsInput -Name 'DestinationMachineName' -Require),
    [Parameter()]
    [string]
    $_destinationPath = (Get-VstsInput -Name 'DestinationPath' -Require),
    [Parameter()]
    [string]
    $_destAdminLogin = (Get-VstsInput -Name 'DestAdminLogin'),
    [Parameter()]
    [string]
    $_destAdminPassword = (Get-VstsInput -Name 'DestAdminPassword'),
    [Parameter()]
    [string]
    $_createZip = (Get-VstsInput -Name 'CreateZip'),
    [Parameter()]
    [string]
    $_zipFileName = (Get-VstsInput -Name 'ZipFileName')
)
Trace-VstsEnteringInvocation $MyInvocation