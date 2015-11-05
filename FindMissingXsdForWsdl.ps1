# Find missing .xsd files that a given .wsdl file depends on.
# Also, create a bare-boned .xsd files (it is necessary to create a given .xsd file to find the next missing .xsd file).
# Some variables in this code will have to be changed to adapt it to your needs.

function Create-MissingXsd()
{	
	# Read output from wsdl.exe into file so we can get a handle on it.	
	# How to catch output from .exe programs http://chuchuva.com/pavel/2010/03/how-to-redirect-output-of-console-program-to-a-file-in-powershell/	
	# And for your education, how to catch output from native PowerShell functions 
	# http://www.vexasoft.com/blogs/powershell/7255220-powershell-tutorial-try-catch-finally-and-error-handling-in-powershell
	cmd /c wsdl.exe .\CBSInterface_BC_Services.wsdl `>out.txt 2`>`&1
	
	# Read the output from the file into a variable.
	[string]$wd = Get-Location
	$outPath = $wd + "\out.txt"	
	$wsdlOutContent = Get-Content $outPath -Raw 	
	# Write-Host $wsdlOutContent
	
	# Parse the variable for the missing .xsd file.
	$start = $wsdlOutContent.IndexOf("bc\") + 3	
	$end = $wsdlOutContent.IndexOf(".xsd") + 4	
	$length = $end - $start	
	$missingXsdName = $wsdlOutContent.Substring($start, $length)	
	if (!$missingXsdName.Contains(".xsd"))
	{
		# Delete out.txt
		Remove-Item $outPath
		return "No .xsd file found in wsdl output info"
	}
	Write-Host "Next missing .xsd file is $missingXsdName"
	
	# Create the missing .xsd file.
	New-Item $missingXsdName -itemtype file
	
	# Add necessary content (though not all the content needed) for wsdl.exe to accept the .xsd file as valid.
	# Also add two import lines in the hopes of that helping.
	$necessaryContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:bccommon="http://www.huawei.com/bme/cbsinterface/bccommon" elementFormDefault="qualified" attributeFormDefault="unqualified">	
	<xs:import namespace="http://www.huawei.com/bme/cbsinterface/cbscommon" schemaLocation="CBSInterface_MessageHeader.xsd"/>
	<xs:import namespace="http://www.huawei.com/bme/cbsinterface/bccommon" schemaLocation="CBSInterface_BC_Common.xsd"/>
</xs:schema>
"@		
	Set-Content -path $missingXsdName -value $necessaryContent
	
	# Delete out.txt
	Remove-Item $outPath
	
	return $wsdlOutContent
}

Do
{	
	[string]$content = Create-MissingXsd
	# Write-Host "The wsdl output info is $content"
	$condition = $content.Contains("Error: Could not find file")			
} While ($condition)
