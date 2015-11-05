# ExpandProperty http://stackoverflow.com/questions/9281565/how-to-extract-the-text-from-a-microsoft-iis-powershell-framework-configuratione
# AppPool Process Id http://stackoverflow.com/questions/7014536/how-to-get-iis-apppool-worker-process-id

function Get-ThreadsForAppPool($AppPool, [switch]$Verbose)
{	
	<#
    .SYNOPSIS 
     Gets information about threads in a process for a given AppPool.
    .DESCRIPTION
	 We assume that there is only one worker process per application pool.
     Relies on the WebAdministration module that is included in the 'IIS: Management Script and Tools' package for IIS.
	 Note that the IIS:\ provider caches worker process information. So if you rerun this script you might be looking at cached information.
	 See more here http://stackoverflow.com/a/7014658/1728563
	.EXAMPLE	 
	 Get-ThreadsForAppPool "SomeAppPoolName" -Verbose
	 Prints summary information as well as detailed information about each thread.
	#>

	Import-Module WebAdministration		
	$wpDir = "IIS:AppPools\$AppPool\WorkerProcesses"
	Write-Host "Checking worker processes at $wpDir"	
	$wp = Get-ChildItem $wpDir
	if ($wp -eq $null) 
	{
		Write-Host "No worker processes found for $AppPool." 
		Write-Host "Keep in mind though that the IIS:\ provider caches worker process information, see more here http://stackoverflow.com/a/7014658/1728563"
		return
	}
	$prid = $wp | Select -expand processId
	Write-Host "AppPool $AppPool uses process with id $prid."
	$threadsNotExpanded = Get-Process -Id $prid | Select Threads
	$threads = $threadsNotExpanded | Select -ExpandProperty Threads
	$nThreads = $threads.Count
	$nThreadsNotWait = $threads | Where {$_.ThreadState -ne "Wait"}
	if ($nThreadsNotWait -eq $null)
	{
		$nThreadsNotWait = 0
	}
	Write-Host "The process is using $nThreads threads."
	Write-Host "$nThreadsNotWait of them are NOT in the 'Wait' state."	
	
	if ($Verbose)
	{
		$threadsNotExpanded | Select -ExpandProperty Threads
	}
	
}

Export-ModuleMember -Function 'Get-ThreadsForAppPool'