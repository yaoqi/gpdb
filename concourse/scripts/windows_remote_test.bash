echo "name: $(cat terraform/name)"
echo "metadata: $(cat terraform/metadata)"
ls terraform
sleep 300
exit 1

$user = "gpadmin"
$pass = ConvertTo-SecureString -String "(BL%2Uuf:UI5NW[" -AsPlainText -Force
$creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $pass
Enter-PSSession -ComputerName 35.203.166.14 -Authentication Negotiate -Credential $creds