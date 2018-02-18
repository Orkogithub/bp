$Script = {

    # Mssql 2014 Standard
	$DriveLetter = $(Get-Partition -DiskNumber 1 -PartitionNumber 2 | select DriveLetter -ExpandProperty DriveLetter)
    $location = "@@{install_location}@@"
    $HOSTNAME=$(hostname)
    $PackageName = "MsSqlServer2014Standard"
    $Prerequisites = "Net-Framework-Core"
    $filePath = "D:\"
    $silentArgs = "/IACCEPTSQLSERVERLICENSETERMS /Q /ACTION=install /FEATURES=SQLENGINE,REPLICATION,FULLTEXT,CONN,IS,BC,SDK,BOL,SSMS,ADV_SSMS /ASSYSADMINACCOUNTS=$HOSTNAME\Administrator /SQLSYSADMINACCOUNTS=$HOSTNAME\Administrator /INSTANCEID=MSSQLSERVER /INSTANCENAME=MSSQLSERVER /UPDATEENABLED=TRUE /INDICATEPROGRESS /TCPENABLED=1 /INSTALLSQLDATADIR=`"${DriveLetter}:\Microsoft SQL Server`""


    #if ($location -eq "external"){
##        $url = "http://care.dlservice.microsoft.com/dl/download/6/D/9/6D90C751-6FA3-4A78-A78E-D11E1C254700/SQLServer2014SP2-FullSlipstream-x64-ENU.iso"
##        $validExitCodes = @(0)
##        New-Item -ItemType Directory -Force -Path $TempDirectory
##       (New-Object System.Net.WebClient).DownloadFile($url,$filePath)
##        } elseif ($location -eq "internal"){
        #$file_share_username = "@@{file_share_user}@@"
        #$file_share_password = "@@{file_share_password}@@"

        #$file_server_ip = "@@{file_server_ip}@@"
        #$file_share_name = "@@{file_share_name}@@"
        #$sql_iso_path = "@@{sql_iso_path}@@"
        #$mapped_drive = "@@{mapped_drive}@@"

        #$validExitCodes = @(0)

        #New-Item -ItemType Directory -Force -Path $TempDirectory

##        $SecurePassword = ConvertTo-SecureString "$file_share_password" -AsPlainText -Force
##        $file_share_credential = New-Object System.Management.Automation.PSCredential ("$file_share_username", $SecurePassword)
##        New-PSDrive –Name $mapped_drive –PSProvider FileSystem –Root “\\$file_server_ip\$file_share_name” –Persist -Credential $file_share_credential

  ##      Try
  ##      {
  ##      	Copy-Item ${mapped_drive}:$sql_iso_path $TempDirectory -Recurse -ErrorAction Stop
  ##  	}
  ##      Catch
##        {
##            Write-Error "Failed to copy SQL Server 2014 ISO"
##            Write-Error $_.Exception
##            Exit -1
##        }
##	}

##      else {
##      		Write-Error "location is not valid. Please specifiy 'internal' or 'external' for variable install_location"
##            Exit -1

##      }



    if ($Prerequisites){
        Install-WindowsFeature -IncludeAllSubFeature -ErrorAction Stop $Prerequisites
    }


    $setupDriveLetter = (Mount-DiskImage -ImagePath $filePath -PassThru | Get-Volume).DriveLetter + ":"
    $setupPath = "$setupDriveLetter\setup.exe"

    Write-Output "Installing $PackageName...."

    $secpasswd = ConvertTo-SecureString "@@{WINDOWS.secret}@@" -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential("@@{WINDOWS.username}@@",$secpasswd)

    $install = Start-Process -FilePath $setupPath -ArgumentList $silentArgs -Wait -NoNewWindow -PassThru -Credential $credential
    $install.WaitForExit()

    $exitCode = $install.ExitCode
    $install.Dispose()

    Write-Output "Command [`"$setupPath`" $silentArgs] exited with `'$exitCode`'."
    if ($validExitCodes -notcontains $exitCode) {
        Write-Output "Running [`"$setupPath`" $silentArgs] was not successful. Exit code was '$exitCode'. See log for possible error messages."
    }

}


$adminpassword = ConvertTo-SecureString -asPlainText -Force -String "@@{WINDOWS.secret}@@"
$Creds = New-Object System.Management.Automation.PSCredential("@@{WINDOWS.username}@@",$adminpassword)

Invoke-Command -ComputerName @@{address}@@ -Credential $Creds -ScriptBlock $script -Authentication Credssp
