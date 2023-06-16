#Let's login, may launch a browser to authenticate the session.
Connect-AzAccount -SubscriptionName 'Demonstration Account'


#Ensure you're pointed at your correct subscription
Set-AzContext -SubscriptionName 'Demonstration Account'


#Create a Resource Group
New-AzResourceGroup -Name "psdemo-rg" -Location "CentralUS"


#Create a credential to use in the VM creation
$username = 'demoadmin'
$password = ConvertTo-SecureString 'password123$%^&*' -AsPlainText -Force
$WindowsCred = New-Object System.Management.Automation.PSCredential ($username, $password)


#Create a Windows Virtual Machine, can be used for both Windows and Linux.
#Note, you can create Windows or Linux VMs with PowerShell by specifying the correct Image parameter.
New-AzVM `
    -ResourceGroupName 'psdemo-rg' `
    -Name 'psdemo-win-az' `
    -Image 'Win2019Datacenter' `
    -Credential $WindowsCred `
    -OpenPorts 3389


#Get the Public IP Address
Get-AzPublicIpAddress `
    -ResourceGroupName 'psdemo-rg' `
    -Name 'psdemo-win-az' | Select-Object IpAddress

#TODO: Open an RDP Client and log into it using this IP address and the credential defined above.


#Clean up after this demo
Remove-AzResourceGroup -Name 'psdemo-rg'

