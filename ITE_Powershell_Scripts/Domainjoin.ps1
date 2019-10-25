#Setup questions
$servername=Read-Host "Enter Servername(s) or path to tab delimited text file"
$creds= Get-Credential -Message "Enter local admin credentials for servers"
#Work
$servername=$servername.Split(",") | ForEach-Object{$_.trim()}
$session= New-PSSession -ComputerName $servername -Credential $creds
Write-Host "Joining $servername to boyd.local"
Invoke-Command -Session $session -ScriptBlock {
    Add-Computer -DomainCredential $creds -DomainName boyd.local -NewName $servername -OUPath "OU=ATI-Oasis,OU=Servers,DC=boyd,DC=local" -Restart
}
Get-PSSession | Remove-PSSession