$domain = "@@{DomainName}@@"
$password = "@@{nutanixlab_Domain_Admin.secret}@@" | ConvertTo-SecureString -asPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential("@@{nutanixlab_Domain_Admin}@@",$password)
Rename-Computer -NewName @@{MSSQL_VMName}@@
Add-computer -DomainName $domain -Credential $credential -force -restart -Options JoinWithNewName,AccountCreate -PassThru -ErrorAction Stop
