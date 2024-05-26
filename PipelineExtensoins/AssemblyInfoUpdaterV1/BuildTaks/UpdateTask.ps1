[CmdletBinding()] 
param() 
 
Trace-VstsEnteringInvocation $MyInvocation 
try { 
    # Get inputs. 
    $searchPattern = Get-VstsInput -Name 'SerachPattern' -Require

    Import-Module "$PSScriptRoot\ps_modules\VstsTaskSdk"
    $regexExpression = '(?m)^\s*[\[\<]\s*[Aa]ssembly:\s*(\w*)\(\s*@?"([^"]*)'


    Write-TaskVerbose -Message "SearchPattern $($searchPattern)"
    Write-TaskVerbose -Message "RegexExpression $($regexExpression)"

    function Set-Variable ([string]$varriableName, [string]$varriableValue)
    {
        Write-SetVariable -Name $varriableName -Value $varriableValue
	    Write-Output ("##vso[task.setvariable variable=" + $varriableName + ";]" +  $varriableValue )
    }

    $fileList = Get-ChildItem -Path $searchPattern -Recurse

    Write-TaskVerbose -Message "Count of files $($fileList.Count)"

    if ($fileList.Count -eq 0)
    {
        Write-TaskWarning -Message "No files matching pattern found." -ErrCode "1" -SourcePath "UpdateTask.ps1" -LineNumber "22"
    }

    if ($fileList.Count -gt 1)
    {
        Write-TaskWarning -Message "Multiple assemblyinfo files found." -ErrCode "1" -SourcePath "UpdateTask.ps1" -LineNumber "22"
    }

    foreach ($file in $fileList)
    {
        Write-TaskVerbose -Message "Start read file."
        Write-TaskDebug -Message ("Start read file. File: " + $file)
    }
} finally { 
    Trace-VstsLeavingInvocation $MyInvocation 
}