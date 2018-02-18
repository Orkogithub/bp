$domain = "@@{DomainName}@@"
$password = "@@{nutanixlab_Domain_Admin.secret}@@" | ConvertTo-SecureString -asPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential("@@{nutanixlab_Domain_Admin}@@",$password)
$Script = {

Get-Disk -Number 1 | Initialize-Disk -ErrorAction SilentlyContinue
New-Partition -DiskNumber 1 -UseMaximumSize -AssignDriveLetter -ErrorAction SilentlyContinue | Format-Volume -Confirm:$false

}

Invoke-Command -ComputerName @@{address}@@ -Credential $credential  -ScriptBlock $script -Authentication Credssp
