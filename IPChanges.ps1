

param([String]$Inventory, [String]$VC)

# Getting credentials
do {
	$user = Read-Host -Prompt 'source vCenter'
	$pass = Read-Host -AsSecureString -Prompt 'vCenter password '
	$cont = Read-Host -Prompt 'Type y to continue'
   } while($cont -ne 'y')
$cred = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $user, $pass

# Connecting to vCenter
Write-Host 'Connecting to' $VC '..'
Connect-VIServer -Server $VC -Credential $cred | Out-Null

#Ensure you are connected to the correct vCenter
if(!$DefaultVIServer -or $DefaultVIServer.Name -ne $VC) {
	Write-Host -Fore:Red 'Connection to vCenter' $SourceVC 'failed, exiting..'
	exit
} else {
	Write-Host 'Connection to vCenter' $SourceVC 'succeeded'
	Write-Host
}

# Processing CSV. You need the following columns in the CSV file: ServerName, Username, Password, NewPortgroup,origIP,newIP,newMask,newGateway 
$csv = @()
$csv = Import-CSV -Path $Inventory | Where {$_.ServerName}
$csv | % {
    $_.ServerName = $_.ServerName.Trim()
    $_.Username = $_.Username.Trim()
    $_.Password = $_.Password.Trim()
    $_.NewPortgroup = $_.NewPortgroup.Trim()
    $_.origIP = $_.origIP.Trim()
    $_.newIP = $_.newIP.Trim()
    $_.newMask = $_.newMask.Trim()
    $_.newGateway = $_.newGateway.Trim()
    }


# Updating VMs' Portgroups and IP Addresses

foreach ($vm in $csv){

    #Check if the Portgroup exists. Get the correct PG in case there is more than one PG with identical name
	$PG= get-virtualswitch -VM $vm.ServerName | get-virtualportgroup | ?{$_.Name -eq $vm.NewPortgroup}
	if(!$PG){
	Write-Host -Fore:Red "The Portgroup" $vm.NewPortgroup "was not found. Proceeding to the next VM"
	Continue
	}
	#Change Portgroup
	Write-Host -Fore:Yellow "Connecting" $vm.ServerName "to Portgroup" $vm.NewPortgroup 
    $nic = (get-vm -name $vm.ServerName) | get-NetworkAdapter
    Set-NetworkAdapter -NetworkAdapter $nic -Portgroup $PG -Confirm:$false 


	# Changing IP Address
	
	# Check if VM is powered on and if it has the VMtools running 
    if($vm.PowerState -eq 'PoweredOff' -or $vm.ExtensionData.Guest.ToolsRunningStatus -eq 'guestToolsNotRunning') { 
		Write-Host -Fore:Red $VM ' is powered off and the IP address of the VM cannot be updated'
	} else {
        # Check if Guest OS is Windows 2012
        if ((Get-vm -name $vm.Servername).Guest.OSFullName -eq "Microsoft Windows Server 2012 (64-bit)"){
         
            # Get the Interface Name 
            $script = '(Get-NetIPAddress | where-object {$_.IPAddress -match "' + $vm.origIp + '" -and $_.AddressFamily -eq "IPv4"}).InterfaceAlias'
            $InterfaceName = invoke-vmscript -ScriptText $script -ScriptType PowerShell -VM $vm.ServerName -GuestUser $vm.Username -GuestPassword $vm.Password
            $InterfaceName = $InterfaceName -replace "`t|`n|`r",""
            if(!$InterfaceName) {
				Write-Host -Fore:Red "The Interface with IP Address" $vm.origIP " was not found in VM" $vm.ServerName "`n"
				Continue
				}

            #Change the IP Address
            Write-host -Fore:Yellow "`nChanging IP Address of" $vm.ServerName "interface" $InterfaceName "from" $vm.origIp "to" $vm.newIp
            $changingIp = '%WINDIR%\system32\netsh.exe interface ipv4 set address name="' + $InterfaceName + '" source=static address=' + $vm.newIP + ' mask=' + $vm.newMask + ' gateway=' + $vm.newGateway + ' gwmetric=1 store=persistent'
            $setIp = invoke-vmscript -ScriptText $changingIp -ScriptType bat -VM $vm.ServerName -GuestUser $vm.Username -GuestPassword $vm.Password            
            }
        
        # For all other Windows Guest OS types
        else {
            # Get the Interface Name
            $InterfaceName = Get-VMGuestNetworkInterface -VM $vm.ServerName -GuestUser $vm.Username -GuestPassword $vm.Password | where {$_.IP -match $vm.OrigIP}
			if(!$InterfaceName) {
				Write-Host -Fore:Red "The Interface with IP Address" $vm.origIP " was not found in VM" $vm.ServerName "`n"
				Continue
				}
            #Change the IP Address
            Write-host -Fore:Yellow "`nChanging IP Address of" $vm.ServerName "interface" $InterfaceName "from" $vm.origIp "to" $vm.newIp
            Set-VMGuestNetworkInterface -VMGuestNetworkInterface $InterfaceName -GuestUser $vm.Username -GuestPassword $vm.Password -Ip $vm.NewIP -Netmask $vm.NewMask -Gateway $vm.NewGateway
            }  
    
    # Register the new IP Address with DNS
    Write-Host -Fore:Yellow "Registering with DNS"
    $registeringDNS = '%WINDIR%\System32\ipconfig /registerdns'
    $segDNS = invoke-vmscript -ScriptText $registeringDNS -ScriptType bat -VM $vm.ServerName -GuestUser $vm.Username -GuestPassword $vm.Password
    Write-Host -Fore:Green $vm.ServerName "has been sucessfully updated `n"
	}
}
Disconnect-VIServer -Confirm:$false