#This should be run from the ATI local jump server (LVSVITA)
#Create a line by line list of servernames
#Maybe update this to ask for filename later...
#Create checks to see if directory exists, or ask if we want to copy, install, or both...
foreach($srvname in Get-Content .\desktop\serverlist.txt) {
Write-Host "Copying dotnet to $srvname"
	copy-item "e:\dotnet\2012\sxs\" -destination "\\$srvname\c$\sxs" -Recurse
Write-Host "Finished copying to $srvname"
Write-Host "Installing dotnet to $srvname"
    install-windowsfeature net-framework-core -source "C:\sxs" -computer $srvname
Write-Host "Finished installing to $srvname"
	}