#Install PowerCLI
#Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
#Install-Module -Name VMware.PowerCLI -AllowClobber -Force -Confirm:$false

#Enter vCenter Name
$vCenter = Read-Host "vCenter Name to extract from"

#Enter VM Name
$vmName = Read-Host "VM Name to extract"

#Save OVA to current user desktop
#$DesktopPath = "C:\Users\matt\Desktop"
$DesktopPath = [Environment]::GetFolderPath("Desktop")

#Export OVA file
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -confirm:$false
Connect-VIServer $vCenter -Force
Export-VM -VM (Get-VM $vmName) -Name $vmName -Destination $DesktopPath -Format Ova -Verbose -Force
