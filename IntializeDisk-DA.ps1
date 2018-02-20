$Script = {

Get-Disk -Number 1 | Initialize-Disk -ErrorAction SilentlyContinue
New-Partition -DiskNumber 1 -UseMaximumSize -AssignDriveLetter -ErrorAction SilentlyContinue | Format-Volume -Confirm:$false

}

$adminpassword = ConvertTo-SecureString -asPlainText -Force -String "@@{WINDOWS.secret}@@"
$Creds = New-Object System.Management.Automation.PSCredential("@@{WINDOWS.username}@@",$adminpassword)

Invoke-Command -ComputerName @@{address}@@ -Credential $Creds -ScriptBlock $script -Authentication Credssp
