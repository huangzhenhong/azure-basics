# define variables
let rNum=$RANDOM*$RANDOM
myLocation=<myLocation>
myTopicName="az204-egtopic-${rNum}"
mySiteName="az204-egsite-${rNum}"
mySiteURL="https://${mySiteName}.azurewebsites.net"

# Create resource group 
az group create --name az204-evgrid-rg --location $myLocation

# Register the Event Grid resource provider
az provider register --namespace Microsoft.EventGrid
az provider show --namespace Microsoft.EventGrid --query "registrationState"

# Create a custom topic 
az eventgrid topic create --name $myTopicName \
    --location $myLocation \
    --resource-group az204-evgrid-rg


https://docs.microsoft.com/en-us/learn/modules/azure-event-grid/8-event-grid-custom-events


