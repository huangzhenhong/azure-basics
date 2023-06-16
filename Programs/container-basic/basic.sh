# Create a resource group for the registry
az group create --name az204-acr-rg --location eastasia

# Create a basic container registry
az acr create --resource-group az204-acr-rg --name azacrdemo007 --sku Basic

# Create a Dockerfile      
echo FROM mcr.microsoft.com/hello-world > Dockerfile    
    
# builds the image and, after the image is successfully built, pushes it to your registry   
az acr build --image hello-world:v1 --registry azacrdemo007.azurecr.io --file Dockerfile .
    
# Use the az acr repository list command to list the repositories in your registry 
az acr repository list --name <myContainerRegistry> --output table

# Use the az acr repository show-tags command to list the tags on the sample/hello-world repository.

az acr repository show-tags --name <myContainerRegistry> \
    --repository sample/hello-world --output table   

#Run the sample/hello-world:v1 container image from your container registry by using the az acr run command.  
az acr run --registry <myContainerRegistry> \
    --cmd '$Registry/sample/hello-world:v1' /dev/null

# Clean up resources
az group delete --name az204-acr-rg --no-wait 