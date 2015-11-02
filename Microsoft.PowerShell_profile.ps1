Write-Host "Running PowerShell Profile at $PROFILE`n"

$execPolicy = "Unrestricted"
Write-Host "Setting ExecutionPolicy to $execPolicy`n"

Set-ExecutionPolicy $execPolicy
Write-Host "PowerShell installation directory is $PSHome`n"

Write-Host "PsGetDestinationModulePath is $PsGetDestinationModulePath`n"

Write-Host "Environment variable PSModulePath is $env:PSModulePath`n"

Write-Host "Importing module WebAdministration`n"
Import-Module WebAdministration

$Providers = Get-PSDrive | Select-Object Name | Out-String
Write-Host "Available Providers (use Set-Location ProviderName:) $Providers"

New-Alias sublime "C:\Program Files\Sublime Text 2\sublime_text.exe"
Set-Alias -Name ls -Value PowerLS -Option AllScope

function which($name)
{
    Get-Command $name | Select-Object -ExpandProperty Definition
}
