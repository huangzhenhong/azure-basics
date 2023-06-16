#Let's login, may launch a browser to authenticate the session.
Connect-AzAccount -SubscriptionName 'Demonstration Account'


#Ensure you're pointed at your correct subscription
Set-AzContext -SubscriptionName 'Demonstration Account'


#If you resources already exist, you can use this to remove the resource group
Remove-AzResourceGroup -Name 'psdemo-rg'


#Recreate the Resource Group
New-AzResourceGroup -Name 'psdemo-rg' -Location 'CentralUS'


#We can deploy ARM Templates using the Portal, Azure CLI or PowerShell
#Make sure to set the adminPassword parameter in parameters.json around line 80 prior to deployment.
#Once finished, look for ProvisioningState Succeeded.
New-AzResourceGroupDeployment `
    -Name mydeployment -ResourceGroupName 'psdemo-rg' `
    -TemplateFile './template/template.json' `
    -TemplateParameterFile './template/parameters.json' 
