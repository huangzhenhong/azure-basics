#Login interactively and set a subscription to be the current active subscription
az login
az account set --subscription "Demonstration Account"


#Let's create a Windows VM.
az group list --output table 


#Create a resource group if needed.
az group create \
    --name "psdemo-rg" \
    --location "centralus"


#Creating a Windows Virtual Machine
az vm create \
    --resource-group "psdemo-rg" \
    --name "psdemo-win-cli" \
    --image "win2019datacenter" \
    --admin-username "demoadmin" \
    --admin-password "password123$%^&*" 


#Open RDP for remote access, it may already be open
az vm open-port \
    --resource-group "psdemo-rg" \
    --name "psdemo-win-cli" \
    --port "3389"


#Get the IP Addresses for Remote Access
az vm list-ip-addresses \
    --resource-group "psdemo-rg" \
    --name "psdemo-win-cli" \
    --output table


#TODO: Log into the Windows VM via RDP.




#Creating a Linux Virtual Machine
az vm create \
    --resource-group "psdemo-rg" \
    --name "psdemo-linux-cli" \
    --image "UbuntuLTS" \
    --admin-username "demoadmin" \
    --authentication-type "ssh" \
    --ssh-key-value ~/.ssh/id_rsa.pub 


#OpenSSH for remote access, it may already be open
az vm open-port \
    --resource-group "psdemo-rg" \
    --name "psdemo-linux-cli" \
    --port "22"



#Get the IP address for Remote Access
az vm list-ip-addresses \
    --resource-group "psdemo-rg" \
    --name "psdemo-linux-cli" \
    --output table


#Log into the Linux VM over SSH
ssh demoadmin@PASTE_PUBLIC_IP_HERE


#Clean up the resources in this demo for the next demo.
az group delete --name "psdemo-rg"
