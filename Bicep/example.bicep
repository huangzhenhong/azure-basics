param publicIpNamePrefix string 

@description('Enter the location to deploy the resource to')
param location string = resourceGroup().location 

var publicIpName = '${publicIpNamePrefix}-pip'

resource publicIp 'Microsoft.Network/publicIpAddresses@2020-06-01' = {
    name: publicIpName
    location: location
    properties: {
        publicIPAllocationMethod:'Static'
    }
}

output ipAddress string = publicIp.properties.ipAddress
