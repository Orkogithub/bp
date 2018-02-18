#CreateDC3Prereqs.ps1

#set static IP address
$ipaddress = "10.21.30.102"
$ipprefix = "25"
$ipgw = "10.21.30.1"
$ipdns = "10.21.253.10"
$ipif = (Get-NetAdapter).ifIndex
New-NetIPAddress -IPAddress $ipaddress -PrefixLength $ipprefix -InterfaceIndex $ipif -DefaultGateway $ipgw
Set-DnsClientServerAddress -InterfaceIndex $ipif -ServerAddresses $ipdns

#rename the computer
$newname = "POC30AD"
Rename-Computer -NewName $newname -force

#install AD DS Role and tools
Add-WindowsFeature -Name "ad-domain-services" -IncludeAllSubFeature -IncludeManagementTools

#restart the computer
Restart-Computer
