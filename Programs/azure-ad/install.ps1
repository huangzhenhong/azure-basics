# install the AzureAD Module 

Install-Module AzureAD

# Connect to Azure AD

$AzureAdCred = Get-Credential 
Connect-AzureAD -Credential $AzureAdCred

# Get all the commands available 
Help AzureAD
 
Help Get-AzureADApplication -examples


