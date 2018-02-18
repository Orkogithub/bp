$Script = {

    # Mssql 2014 (Express,Standard)
	$DriveLetter = $(Get-Partition -DiskNumber 1 -PartitionNumber 2 | select DriveLetter -ExpandProperty DriveLetter)
    $edition = "Standard"
    $TempDirectory = "C:\Temp"
    $HOSTNAME=$(hostname)
    $DOMAINNAME=(Get-WmiObject Win32_ComputerSystem).Domain
    if ($edition -eq "Express"){
        $PackageName = "MsSqlServer2014Express"
        $url = "https://download.microsoft.com/download/2/A/5/2A5260C3-4143-47D8-9823-E91BB0121F94/SQLEXPR_x64_ENU.exe"
        $silentArgs = "/IACCEPTSQLSERVERLICENSETERMS /Q /ACTION=install /INSTANCEID=SQLEXPRESS /INSTANCENAME=SQLEXPRESS /UPDATEENABLED=FALSE /INDICATEPROGRESS"
        $filePath = "$TempDirectory\SQLEXPR.exe"
        $extractPath = "$TempDirectory\SQLEXPR"
        $setupPath = "$extractPath\setup.exe"
        $fileType = 'exe'
        $validExitCodes = @(0, 3010)
    } elseif ($edition -eq "Standard"){
        $PackageName = "MsSqlServer2014Standard"
        $Prerequisites = "Net-Framework-Core"
        $url = "http://care.dlservice.microsoft.com/dl/download/6/D/9/6D90C751-6FA3-4A78-A78E-D11E1C254700/SQLServer2014SP2-FullSlipstream-x64-ENU.iso"
        $silentArgs = "/IACCEPTSQLSERVERLICENSETERMS /Q /ACTION=install /FEATURES=SQLENGINE,REPLICATION,FULLTEXT,DQ,AS,RS,RS_SHP,RS_SHPWFE,DQC,CONN,IS,BC,SDK,BOL,SSMS,ADV_SSMS,DREPLAY_CTLR,DREPLAY_CLT,SNAC_SDK,MDS /ASSYSADMINACCOUNTS=$HOSTNAME\Administrator /SQLSYSADMINACCOUNTS=`"$HOSTNAME\Administrator`" `"$DOMAINNAME\Domain Admins`" /INSTANCEID=MSSQLSERVER /INSTANCENAME=MSSQLSERVER /UPDATEENABLED=TRUE /INDICATEPROGRESS /TCPENABLED=1 /INSTALLSQLDATADIR=`"${DriveLetter}:\Microsoft SQL Server`""
        #$filePath = "$TempDirectory\MSSQL_2014.iso"
        $fileType = 'iso'
        $validExitCodes = @(0)
    }


    #New-Item -ItemType Directory -Force -Path $TempDirectory
    #(New-Object System.Net.WebClient).DownloadFile($url,$filePath)

    if ($Prerequisites){
        Install-WindowsFeature -IncludeAllSubFeature -ErrorAction Stop $Prerequisites
    }

    #if ($fileType -eq 'exe'){
    #    Write-Output "Extracting..."
    #    Start-Process "$filePath" "/Q /x:`"$extractPath`"" -Wait
    #} elseif ($fileType -eq 'iso'){
    #      $setupDriveLetter = "D:"
    #      $setupPath = "$setupDriveLetter\setup.exe"
    #}
    $setupDriveLetter = "D:"
    $setupPath = "$setupDriveLetter\setup.exe"
    Write-Output "Installing $PackageName...."

    #$secpasswd = "@@{WINDOWS.secret}@@" | ConvertTo-SecureString -asPlainText -Force
    #$credential = New-Object System.Management.Automation.PSCredential("@@{WINDOWS.username}@@",$secpasswd)

    $secpasswd = "@@{nutanixlab_Domain_Admin.secret}@@" | ConvertTo-SecureString -asPlainText -Force
	$credential = New-Object System.Management.Automation.PSCredential("@@{nutanixlab_Domain_Admin.username}@@",$secpasswd)

    $install = Start-Process -FilePath $setupPath -ArgumentList $silentArgs -Wait -NoNewWindow -PassThru -Credential $credential
    $install.WaitForExit()

    $exitCode = $install.ExitCode
    $install.Dispose()

    Write-Output "Command [`"$setupPath`" $silentArgs] exited with `'$exitCode`'."
    if ($validExitCodes -notcontains $exitCode) {
        Write-Output "Running [`"$setupPath`" $silentArgs] was not successful. Exit code was '$exitCode'. See log for possible error messages."
    }

}

#$adminpassword = "@@{WINDOWS.secret}@@" | ConvertTo-SecureString -asPlainText -Force
#$Creds = New-Object System.Management.Automation.PSCredential("@@{WINDOWS.username}@@",$adminpassword)

$password = "@@{nutanixlab_Domain_Admin.secret}@@" | ConvertTo-SecureString -asPlainText -Force
$Creds = New-Object System.Management.Automation.PSCredential("@@{nutanixlab_Domain_Admin.username}@@",$password)


Invoke-Command -ComputerName @@{address}@@ -Credential $Creds -ScriptBlock $script -Authentication Credssp
