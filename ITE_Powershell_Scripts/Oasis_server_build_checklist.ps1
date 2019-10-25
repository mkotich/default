#This script will check several things on a built server to tell us how many Procs, how much RAM, whether or not dotnet3.5 is installed, etc.

$servername=Read-Host "Enter Servername(s) or path to tab delimited text file"
#Get Creds
$ServerCredentials= Get-Credential -Message "Enter credentials for servers"
#Splitting servernames
$servername=$servername.Split(",") | ForEach-Object{$_.trim()}
$session= New-PSSession -ComputerName $servername -Credential $ServerCredentials
#How much PROC and RAM
Invoke-Command -Session $session -ScriptBlock {
#Get-ComputerInfo is a Powershell 5.1 thing and does not work with win2012.
#Get-ComputerInfo | Format-List @{N="Hostname";E={($_.CsName)}}, @{N="Domain";E={($_.CsDomain)}}, @{N="Windows Version";E={($_.WindowsProductName)}}, @{N="Time Zone";E={($_.TimeZone)}}, @{N="Install Date";E={($_.OsInstallDate)}}, @{N="Processors";E={($_.CsNumberOfLogicalProcessors)}}, @{N="Total RAM";E={[math]::round(($_.CsTotalPhysicalMemory/(1024*1024*1024)),2)}}, @{N="Dotnet Version";E={Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5'.version}}
systeminfo | ForEach-Object {if ( `
    $_.contains("Host Name:") -or `
    $_.contains("OS Name:") -or `
    $_.contains("OS Version:") -or `
    $_.contains("Original Install Date:") -or `
    $_.contains("Processor(s):") -or `
    $_.contains("Time Zone:") -or `
    $_.contains("Total Physical Memory:") -or `
    $_.contains("Domain:") -or `
    $_.contains("Hotfix(s):") -or `
    $_.contains("Network Card(s):")) `
{$_}}
#Check for dotnet3.5
Write-Host -NoNewline "Dotnet Version:            "
Invoke-Command -ScriptBlock { (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5').version }
#Networking
Write-Host ""
Write-Host "Networking"
Write-Host "----------"
Invoke-Command -ScriptBlock {
(Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object {$null -ne $_.DefaultIPGateway}).IPAddress
#Display HDD sizes
Write-Host ""
Invoke-Command -ScriptBlock { Get-PSDrive -PSProvider filesystem | Select-Object Name, @{n='Total (GB)' ; e={[math]::Round(("{0:N2}" -f (($_.used + $_.Free)/1GB)))}} | Format-Table -auto
#Display HDDs with 64k block size
Write-Host "HDDs with 64k Block Size:"
Write-Host "-------------------------" 
Invoke-Command -ScriptBlock {
Get-WmiObject win32_volume | Where-Object{$_.BlockSize -eq 65536} | Format-Table DriveLetter, Label, BlockSize -AutoSize
Write-Host "---END OF SEVER---"
Write-Host ""
}}}}
Get-PSSession | Remove-PSSession