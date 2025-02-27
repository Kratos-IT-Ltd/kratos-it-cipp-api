[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Packagename,

    [Parameter()]
    [switch]
    $InstallChoco,

    [Parameter()]
    [string]
    $CustomRepo,

    [Parameter()]
    [switch]
    $Trace
)

$KratosITPrivateRepo = "https://choco.kratoscloud.co.uk/nuget/kit-private-chocolatey/"
$ChocoInstallScriptPath = "https://choco.kratoscloud.co.uk/endpoints/kit-private-assets/content/chocoinstall.ps1"
$PrivateRepoUsername = "api"
$PrivateRepoPassword = "{REDACTED}"
$PrivateRepoCredentials = ('{0}:{1}' -f $PrivateRepoUsername, $PrivateRepoPassword)

try {
    if ($Trace) { Start-Transcript -Path (Join-Path $env:windir "\temp\choco-$Packagename-trace.log") }
    $chocoPath = "$($ENV:SystemDrive)\ProgramData\chocolatey\bin\choco.exe"

    if ($InstallChoco) {
        if (-not (Test-Path $chocoPath)) {
            try {
                Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression (Invoke-WebRequest $ChocoInstallScriptPath -Headers @{"AUTHORIZATION"="Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($PrivateRepoCredentials))})
                $chocoPath = "$($ENV:SystemDrive)\ProgramData\chocolatey\bin\choco.exe"
            }
            catch {
                Write-Host "InstallChoco Error: $($_.Exception.Message)"
            }
        }
    }

    try {
        $localprograms = & "$chocoPath" list
        $CustomRepoString = if ($CustomRepo) { "--source $KratosITPrivateRepo --user '$PrivateRepoUsername' --password '$PrivateRepoPassword'" } else { $null }
        if ($localprograms -like "*$Packagename*" ) {
            Write-Host "Upgrading $packagename"
            & "$chocoPath" upgrade $Packagename $CustomRepoString
        }
        else {
            Write-Host "Installing $packagename"
            & "$chocoPath" install $Packagename -y $CustomRepoString
        }
        Write-Host 'Completed.'
    }  
    catch {
        Write-Host "Install/upgrade error: $($_.Exception.Message)"
    }

}
catch {
    Write-Host "Error encountered: $($_.Exception.Message)"
}
finally {
    if ($Trace) { Stop-Transcript }
}

exit $?
