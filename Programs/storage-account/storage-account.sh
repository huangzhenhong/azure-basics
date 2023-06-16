# Create a resource group
az group create -n az204rg -l japaneast

# create a storage account 
az storage account create -n zzbs -g az204rg --location japaneast --sku Standard_LRS -o jsonc

# show all storage accounts
az storage account list --query "[].{name:name,location:primaryLocation}" -o jsonc

# delete a storage account
az storage account delete -g az204rg -n zzbs

# update access tier 
az storage account update -n zzbs -g az204rg --access-tier Cool

# get storage account details 
az storage account list --query "[].{name:name,location:primaryLocation,group:group,accessTier:accessTier}" -o jsonc

# add/update tags
az storage account update -n zzbs -g az204rg --tags projectName=project1 teamName=teamA

az storage account list --query "[].{name:name,location:primaryLocation,group:group,accessTier:accessTier,tags:tags}" -o jsonc