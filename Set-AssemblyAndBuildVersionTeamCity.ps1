# SetAssemblyVersion.ps1
#
# http://www.luisrocha.net/2009/11/setting-assembly-version-with-windows.html
# http://blogs.msdn.com/b/dotnetinterop/archive/2008/04/21/powershell-script-to-batch-update-assemblyinfo-cs-with-new-version.aspx
# http://jake.murzy.com/post/3099699807/how-to-update-assembly-version-numbers-with-teamcity
# https://github.com/ferventcoder/this.Log/blob/master/build.ps1#L6-L19
# https://gist.github.com/derekgates/4678882 

# Note that this version REQUIRES the following environment variables to be defined in TeamCity
# build_counter with value %build.counter%
# short_git with empty value

# About the different assembly version numbers
# http://stackoverflow.com/questions/64602/what-are-differences-between-assemblyversion-assemblyfileversion-and-assemblyin
 
Param(
    [string]$path
)

function Update-SourceVersion
{
    Param ([string]$version, [string]$infoVersion)
 
	$nAssemblyInfoFiles = @($input).Count
	if ($nAssemblyInfoFiles -eq 0)
	{
		Write-Error "Found no AssemblyInfo.cs files searching $path recursively."
		[System.Environment]::Exit(1)
	}

	Write-Host "Found $nAssemblyInfoFiles AssemblyInfo.cs file(s)."	

	# $input is an enumerator and must be reset since it was consumed during the Count operation above
	# See more here https://dmitrysotnikov.wordpress.com/2008/11/26/input-gotchas/
    $input.Reset()
    foreach ($assemblyFile in $input) 
    {
        Write-Host "Updating  '$($assemblyFile.FullName)' -> {$version, $infoVersion}"
    
		# Check if AssemblyInfo.cs file contains the AssemblyInformationalVerison attribute, it doesn't appear to do so by default.		
		$fileContent = Get-Content $assemblyFile.FullName
		$fileContains = $fileContent -like "*AssemblyInformationalVersion*"
		if (!$fileContains)
		{
			Write-Host "$($assemblyFile.FullName) does not contain the AssemblyInformationalVersion attribute, adding a dummy one to be replaced."
			Add-Content $assemblyFile.FullName "[assembly: AssemblyInformationalVersion(`"1.0.0.0`")]"
		}

		# www.rubular.com is a great website to test regular expressions.
		# The first regexp matches something like 1.2, 1.2.3, 1.2.3.4, 1.0.31.4 or 1.2.3.*
		# The second regexp mathces the same as the first one in addition to something like 1.2.ab34ef5, 1.0.31.ab34ef5 or 1.2.*.ab34cd5
        $assemblyVersionPattern = 'AssemblyVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)'
        $fileVersionPattern = 'AssemblyFileVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)'
		$infoVersionPattern = 'AssemblyInformationalVersion\("[0-9]+(\.([0-9]+|\*)){1,2}(\.(([a-zA-Z]|\d){7}|[0-9]|\*))*"\)'
        
		$assemblyVersion = 'AssemblyVersion("' + $version + '")';
        $fileVersion = 'AssemblyFileVersion("' + $version + '")';
		$informationalVersion = 'AssemblyInformationalVersion("' + $infoVersion + '")';
        
        (Get-Content $assemblyFile.FullName) | ForEach-Object { 
           % {$_ -replace $assemblyVersionPattern, $assemblyVersion } |
           % {$_ -replace $fileVersionPattern, $fileVersion } |
		   % {$_ -replace $infoVersionPattern, $informationalVersion }
        } | Out-File $assemblyFile.FullName -encoding UTF8 -force
    }
}
function Update-AllAssemblyInfoFiles($version, $infoVersion)
{	
	if (!(Test-Path $path))
	{
		Write-Error "Path $path to search for AssemblyInfo.cs files recursively in does not exist."
		[System.Environment]::Exit(1)
	}

    Write-Host "Searching '$path' recursively for AssemblyInfo.cs files."
    $file = "AssemblyInfo.cs"
	get-childitem $path -recurse |? {$_.Name -eq $file} | Update-SourceVersion $version $infoVersion;    
}

function Set-BuildNumber($buildNumber)
{	
	Write-Host "Updating TeamCity build.number build parameter to $buildNumber"
	Write-Host "##teamcity[buildNumber '$buildNumber']"
}

function Set-AssemblyAndBuildNumber()
{
	$buildNumber = $env:build_number
	$buildCounter = $env:build_counter
	
	$hash = $env:build_vcs_number
	$shortHash = $hash.substring(0,7)	
	Write-Host "Setting TeamCity environment parameter short_git to $shortHash"
	Write-Host "##teamcity[setParameter name='env.short_git' value='$shortHash']"
	
	$assemblyVerison = "$buildNumber.$buildCounter"
	if (($assemblyVerison -eq '/?') -or ($assemblyVerison -notmatch "[0-9]+(\.([0-9]+|\*)){1,3}")) 
	{        
        exit 1;
    }
	
	$buildNumberFinal = "$buildNumber.$buildCounter.$shortHash"
	$assemblyInformationalVersion = "$buildNumber.$buildCounter.$shortHash"

	Set-BuildNumber $buildNumberFinal
	Update-AllAssemblyInfoFiles $assemblyVerison $assemblyInformationalVersion
}
 
try
{ 
	Set-AssemblyAndBuildNumber
}
catch
{
	Write-Error $_
    [System.Environment]::Exit(1)
}