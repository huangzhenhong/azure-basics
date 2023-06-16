
# Create a service principal
az ad sp create-for-rbac -n daniel --skip-assignment

# list service principals 
az ad sp list --query []."DisplayName"

# show details of a service principal
az ad sp show --id "c2d09b46-cb91-4366-95aa-99e800b90cf5"


