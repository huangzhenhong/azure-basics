# Create custom Azure resource role

# Ref: https://docs.microsoft.com/en-us/azure/role-based-access-control/tutorial-custom-role-powershell

Get-AzProviderOperation 'Microsoft.Compute/Disks/*' | Format-Table -Property Operation, Description -AutoSize

Get-AzRoleDefinition -Name 'Virtual Machine Contributor' | ConvertTo-Json | Out-File 'C:\Users\zhuae09687\practices\AzurePractices\programmatically\custom-role\VMManager.json'

# Alternatively
(Get-AzRoleDefinition "Virtual Machine Contributor").Actions #NotActions

# Try "VM and Managed Disk Contributor"
"Microsoft.Compute/Disks/*"

Get-AzSubscription | Select-Object -Property id

(Get-AzSubscription -SubscriptionName 'Pay-As-You-Go').id

New-AzRoleDefinition -InputFile 'C:\Users\zhuae09687\practices\AzurePractices\programmatically\custom-role\VMManager.json'

Get-AzRoleDefinition | Where-Object -FilterScript { $_.IsCustom -eq $true } | Format-Table -Property Name, IsCustom

Get-AzRoleDefinition 'VM and Disk Contributor' | Remove-AzRoleDefinition -Force

Get-AzRoleDefinition | Where-Object { $_.IsCustom -eq $true } | Remove-AzRoleDefinition -Force

Remove-AzRoleDefinition -Id '784b2fee-cab5-4fe8-8679-4273888a3e1f'