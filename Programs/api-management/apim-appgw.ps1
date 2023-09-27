# Sign in to Azure 
Connect-AzAccount
# https://techcommunity.microsoft.com/t5/azure-paas-blog/integrating-api-management-with-app-gateway-v2/ba-p/1241650
# https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-integrate-internal-vnet-appgateway
# Select the subscription you want
$subscriptionId = "<Subscription Id>"
Get-AzSubscription -Subscriptionid $subscriptionId | Select-AzSubscription

# Create a resource group
$resGroupName = "apim-appGw-RG"
$location = "East US2"
New-AzResourceGroup -Name $resGroupName -Location $location

# Create a network security group (NSG) and NSG rules for the Application Gateway subnet
$appGwRule1 = New-AzNetworkSecurityRuleConfig -Name appgw-in -Description "AppGw inbound" `
    -Access Allow -Protocol * -Direction Inbound -Priority 100 -SourceAddressPrefix `
    GatewayManager -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 65200-65535
$appGwRule2 = New-AzNetworkSecurityRuleConfig -Name appgw-in-internet -Description "AppGw inbound Internet" `
    -Access Allow -Protocol "TCP" -Direction Inbound -Priority 110 -SourceAddressPrefix `
    Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 443

$appGwNsg = New-AzNetworkSecurityGroup -ResourceGroupName $resGroupName -Location $location -Name `
    "NSG-APPGW" -SecurityRules $appGwRule1, $appGwRule2

# Create a network security group (NSG) and NSG rules for the API Management subnet.
$apimRule1 = New-AzNetworkSecurityRuleConfig -Name APIM-Management -Description "APIM inbound" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix ApiManagement `
    -SourcePortRange * -DestinationAddressPrefix VirtualNetwork -DestinationPortRange 3443
$apimRule2 = New-AzNetworkSecurityRuleConfig -Name AllowAppGatewayToAPIM -Description "Allows inbound App Gateway traffic to APIM" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 110 -SourceAddressPrefix "10.0.0.0/24" `
    -SourcePortRange * -DestinationAddressPrefix "10.0.1.0/24" -DestinationPortRange 443
$apimRule3 = New-AzNetworkSecurityRuleConfig -Name AllowAzureLoadBalancer -Description "Allows inbound Azure Infrastructure Load Balancer traffic to APIM" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 120 -SourceAddressPrefix AzureLoadBalancer `
    -SourcePortRange * -DestinationAddressPrefix "10.0.1.0/24" -DestinationPortRange 6390
$apimRule4 = New-AzNetworkSecurityRuleConfig -Name AllowKeyVault -Description "Allows outbound traffic to Azure Key Vault" `
    -Access Allow -Protocol Tcp -Direction Outbound -Priority 100 -SourceAddressPrefix "10.0.1.0/24" `
    -SourcePortRange * -DestinationAddressPrefix AzureKeyVault -DestinationPortRange 443

$apimNsg = New-AzNetworkSecurityGroup -ResourceGroupName $resGroupName -Location $location -Name `
    "NSG-APIM" -SecurityRules $apimRule1, $apimRule2, $apimRule3, $apimRule4

# Create a virtual network and subnets
$appgatewaysubnet = New-AzVirtualNetworkSubnetConfig -Name "appGatewaySubnet" -NetworkSecurityGroup $appGwNsg -AddressPrefix "10.0.0.0/24"
$apimsubnet = New-AzVirtualNetworkSubnetConfig -Name "APIMSubnet" -NetworkSecurityGroup $apimNsg -AddressPrefix "10.0.1.0/24"
$vmsubnet = New-AzVirtualNetworkSubnetConfig -Name "vmSubnet" -NetworkSecurityGroup $apimNsg -AddressPrefix "10.0.2.0/24"
$bastionSubnet = New-AzVirtualNetworkSubnetConfig -Name "AzureBastionSubnet" -AddressPrefix "10.0.3.0/26"
$vnet = New-AzVirtualNetwork -Name "appgwvnet" -ResourceGroupName $resGroupName `
  -Location $location -AddressPrefix "10.0.0.0/16" -Subnet $appgatewaysubnet, $apimsubnet, $vmsubnet, $bastionSubnet

## $vnet = Get-AzVirtualNetwork -Name "appgwvnet" -ResourceGroupName $resGroupName

$appGatewaySubnetData = $vnet.Subnets[0]
$apimSubnetData = $vnet.Subnets[1]

# Create an API Management service inside a VNET configured in internal mode
# API Management stv2 requires a public IP with a unique DomainNameLabel
$apimPublicIpAddressId = New-AzPublicIpAddress -ResourceGroupName $resGroupName -name "pip-apim" -location $location `
    -AllocationMethod Static -Sku Standard -Force -DomainNameLabel "apim-danieltest"

$apimServiceName = "DanielTestApi001"       # API Management service instance name
$apimOrganization = "DanielTest"          # organization name
$apimAdminEmail = "zhenhong.huang@elekta.com" # administrator's email address

$apimVirtualNetwork = New-AzApiManagementVirtualNetwork -SubnetResourceId $apimSubnetData.Id

$apimService = New-AzApiManagement -ResourceGroupName $resGroupName -Location $location `
  -Name $apimServiceName -Organization $apimOrganization -AdminEmail $apimAdminEmail `
  -VirtualNetwork $apimVirtualNetwork -VpnType "Internal" -Sku "Developer" -PublicIpAddressId $apimPublicIpAddressId.Id

# $apimService = Get-AzApiManagement -ResourceGroupName $resGroupName -Name $apimServiceName

# Create a VM inside the same vnet
# Update the host file 
#
# 10.0.1.4 danieltestapi.azure-api.net
# 10.0.1.4 danieltestapi.portal.azure-api.net
# 10.0.1.4 danieltestapi.management.azure-api.net
# 10.0.1.4 danieltestapi.scm.azure-api.net
#

# # Create a public IP address for the front-end configuration
# $publicip = New-AzPublicIpAddress -ResourceGroupName $resGroupName -Name "publicIP001" -AllocationMethod Dynamic

# Create certificates (Ensure you have the certificates ready)
# how to use 'makecert' command
# https://www.coder.work/article/6613322 

# makecert -n "CN=api.danieltest.com" -r -sv C:\myCerts\gateway.pvk C:\myCerts\gateway.cer
# cd C:\Program Files (x86)\Windows Kits\10\bin\10.0.17763.0\x64\
# pvk2pfx.exe -pvk C:\myCerts\gateway.pvk -spc C:\myCerts\gateway.cer -pfx C:\myCerts\gateway.pfx -pi "certificatePassword123" -f

# makecert -n "CN=portal.danieltest.com" -r -sv C:\myCerts\portal.pvk C:\myCerts\portal.cer
# cd C:\Program Files (x86)\Windows Kits\10\bin\10.0.17763.0\x64\
# pvk2pfx.exe -pvk C:\myCerts\portal.pvk -spc C:\myCerts\portal.cer -pfx C:\myCerts\portal.pfx -pi "certificatePassword123" -f

# makecert -n "CN=management.danieltest.com" -r -sv C:\myCerts\management.pvk C:\myCerts\management.cer
# cd C:\Program Files (x86)\Windows Kits\10\bin\10.0.17763.0\x64\
# pvk2pfx.exe -pvk C:\myCerts\management.pvk -spc C:\myCerts\management.cer -pfx C:\myCerts\management.pfx -pi "certificatePassword123" -f

# Set-up a custom domain name in API Management
# https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-integrate-internal-vnet-appgateway
$domain = "danieltest.com"
$gatewayHostname = "api.$domain"                 # API gateway host
$portalHostname = "portal.$domain"               # API developer portal host
$managementHostname = "management.$domain"       # API management endpoint host
$certPath = "C:\myCerts"
$gatewayCertCerPath = "$certPath\gateway.cer" # full path to api.danieltest.com .cer file
$gatewayCertPfxPath = "$certPath\gateway.pfx" # full path to api.danieltest.com .pfx file
$portalCertPfxPath = "$certPath\portal.pfx"  # full path to portal.danieltest.com .pfx file
$managementCertPfxPath = "$certPath\management.pfx"  # full path to management.danieltest.com .pfx file

$gatewayCertPfxPassword = "certificatePassword123" # password for api.danieltest.com pfx certificate
$portalCertPfxPassword = "certificatePassword123"  # password for portal.danieltest.com pfx certificate
$managementCertPfxPassword = "certificatePassword123" # password for management.danieltest.com pfx certificate

$certGatewayPwd = ConvertTo-SecureString -String $gatewayCertPfxPassword -AsPlainText -Force   # password for api.contoso.net pfx certificate
$certPortalPwd = ConvertTo-SecureString -String $portalCertPfxPassword -AsPlainText -Force  # password for portal.contoso.net pfx certificate
$certManagementPwd = ConvertTo-SecureString -String $managementCertPfxPassword -AsPlainText -Force

$gatewayHostnameConfig = New-AzApiManagementCustomHostnameConfiguration -Hostname $gatewayHostname `
  -HostnameType Proxy -PfxPath $gatewayCertPfxPath -PfxPassword $certGatewayPwd
$portalHostnameConfig = New-AzApiManagementCustomHostnameConfiguration -Hostname $portalHostname `
  -HostnameType DeveloperPortal -PfxPath $portalCertPfxPath -PfxPassword $certPortalPwd
$managementHostnameConfig = New-AzApiManagementCustomHostnameConfiguration -Hostname $managementHostname `
  -HostnameType Management -PfxPath $managementCertPfxPath -PfxPassword $certManagementPwd

$apimService.ProxyCustomHostnameConfiguration = $gatewayHostnameConfig
$apimService.PortalCustomHostnameConfiguration = $portalHostnameConfig
$apimService.ManagementCustomHostnameConfiguration = $managementHostnameConfig

Set-AzApiManagement -InputObject $apimService

#**************** Configure a private zone for DNS resolution in the virtual network *******************#
# Create a private DNS zone and link the virtual network
$myZone = New-AzPrivateDnsZone -Name $domain -ResourceGroupName $resGroupName 
$link = New-AzPrivateDnsVirtualNetworkLink -ZoneName $domain `
  -ResourceGroupName $resGroupName -Name "mylink" `
  -VirtualNetworkId $vnet.id

# Create A-records for the custom domain host names that map to the private IP address of API Management.
$apimIP = $apimService.PrivateIPAddresses[0]

New-AzPrivateDnsRecordSet -Name api -RecordType A -ZoneName $domain `
  -ResourceGroupName $resGroupName -Ttl 3600 `
  -PrivateDnsRecords (New-AzPrivateDnsRecordConfig -IPv4Address $apimIP)
New-AzPrivateDnsRecordSet -Name portal -RecordType A -ZoneName $domain `
  -ResourceGroupName $resGroupName -Ttl 3600 `
  -PrivateDnsRecords (New-AzPrivateDnsRecordConfig -IPv4Address $apimIP)
New-AzPrivateDnsRecordSet -Name management -RecordType A -ZoneName $domain `
  -ResourceGroupName $resGroupName -Ttl 3600 `
  -PrivateDnsRecords (New-AzPrivateDnsRecordConfig -IPv4Address $apimIP)

#**************** Create application gateway *******************#
# Create a Standard public IP resource, An IP address is assigned to the application gateway when the service starts
$publicip = New-AzPublicIpAddress -ResourceGroupName $resGroupName `
  -name "pip-appgateway" -location $location -AllocationMethod Static -Sku Standard
# Create an Application Gateway IP configuration named gatewayIP01.
$gipconfig = New-AzApplicationGatewayIPConfiguration -Name "gatewayIP001" -Subnet $appGatewaySubnetData
# Configure the front-end IP port for the public IP endpoint. 
$fp01 = New-AzApplicationGatewayFrontendPort -Name "port001" -Port 443
# Configure the front-end IP with a public IP endpoint.
$fipconfig01 = New-AzApplicationGatewayFrontendIPConfig -Name "frontend1" -PublicIPAddress $publicip

# Configure the certificates for the Application Gateway
$certGateway = New-AzApplicationGatewaySslCertificate -Name "gatewaycert" `
  -CertificateFile $gatewayCertPfxPath -Password $certGatewayPwd
$certPortal = New-AzApplicationGatewaySslCertificate -Name "portalcert" `
  -CertificateFile $portalCertPfxPath -Password $certPortalPwd
$certManagement = New-AzApplicationGatewaySslCertificate -Name "managementcert" `
  -CertificateFile $managementCertPfxPath -Password $certManagementPwd

# Create the HTTP listerners for the application gateway
$gatewaylistener = New-AzApplicationGatewayHttpListener -Name "gatewaylistener" `
    -Protocol "Https" -FrontendIPConfiguration $fipconfig01 -FrontendPort $fp01 `
    -SslCertificate $certGateway -HostName $gatewayHostname -RequireServerNameIndication $true
$portalListener = New-AzApplicationGatewayHttpListener -Name "portallistener" `
    -Protocol "Https" -FrontendIPConfiguration $fipconfig01 -FrontendPort $fp01 `
    -SslCertificate $certPortal -HostName $portalHostname -RequireServerNameIndication $true
$managementListener = New-AzApplicationGatewayHttpListener -Name "managementlistener" `
    -Protocol "Https" -FrontendIPConfiguration $fipconfig01 -FrontendPort $fp01 `
    -SslCertificate $certManagement -HostName $managementHostname -RequireServerNameIndication $true

# Create custom probes to the API Management gateway domain endpoints
$apimGatewayProbe = New-AzApplicationGatewayProbeConfig -Name "apimgatewayprobe" -Protocol "Https" `
    -HostName $gatewayHostname -Path "/status-0123456789abcdef" -Interval 30 -Timeout 120 -UnhealthyThreshold 8
$apimPortalProbe = New-AzApplicationGatewayProbeConfig -Name "apimportalprobe" -Protocol "Https" `
    -HostName $portalHostname -Path "/signin" -Interval 60 -Timeout 300 -UnhealthyThreshold 8
$apimManagementProbe = New-AzApplicationGatewayProbeConfig -Name "apimmanagementprobe" -Protocol "Https" `
    -HostName $managementHostname  -Path "/ServiceStatus" -Interval 60 -Timeout 300 -UnhealthyThreshold 8

# Upload the certificate to be used on the SSL-enabled backend pool resources
$trustedRootCert = New-AzApplicationGatewayTrustedRootCertificate -Name "allowlistcert1" -CertificateFile $gatewayCertCerPath

# Configure HTTP back-end settings for the application gateway
$apimPoolGatewaySetting = New-AzApplicationGatewayBackendHttpSettings -Name "apimPoolGatewaySetting" `
  -Port 443 -Protocol "Https" -CookieBasedAffinity "Disabled" -Probe $apimGatewayProbe `
  -TrustedRootCertificate $trustedRootCert -PickHostNameFromBackendAddress -RequestTimeout 180
$apimPoolPortalSetting = New-AzApplicationGatewayBackendHttpSettings -Name "apimPoolPortalSetting" `
  -Port 443 -Protocol "Https" -CookieBasedAffinity "Disabled" -Probe $apimPortalProbe `
  -TrustedRootCertificate $trustedRootCert -PickHostNameFromBackendAddress -RequestTimeout 180
$apimPoolManagementSetting = New-AzApplicationGatewayBackendHttpSettings -Name "apimPoolManagementSetting" `
  -Port 443 -Protocol "Https" -CookieBasedAffinity "Disabled" -Probe $apimManagementProbe `
  -TrustedRootCertificate $trustedRootCert -PickHostNameFromBackendAddress -RequestTimeout 180

# Configure a back-end IP address pool for each API Management endpoint by using its respective domain name
$apimGatewayBackendPool = New-AzApplicationGatewayBackendAddressPool -Name "gatewaybackend" `
  -BackendFqdns $gatewayHostname
$apimPortalBackendPool = New-AzApplicationGatewayBackendAddressPool -Name "portalbackend" `
  -BackendFqdns $portalHostname
$apimManagementBackendPool = New-AzApplicationGatewayBackendAddressPool -Name "managementbackend" `
  -BackendFqdns $managementHostname

# Create rules for the application gateway to use basic routing
$gatewayRule = New-AzApplicationGatewayRequestRoutingRule -Name "gatewayrule" `
  -RuleType Basic -HttpListener $gatewayListener -BackendAddressPool $apimGatewayBackendPool `
  -BackendHttpSettings $apimPoolGatewaySetting -Priority 10
$portalRule = New-AzApplicationGatewayRequestRoutingRule -Name "portalrule" `
  -RuleType Basic -HttpListener $portalListener -BackendAddressPool $apimPortalBackendPool `
  -BackendHttpSettings $apimPoolPortalSetting -Priority 20
$managementRule = New-AzApplicationGatewayRequestRoutingRule -Name "managementrule" `
  -RuleType Basic -HttpListener $managementListener -BackendAddressPool $apimManagementBackendPool `
  -BackendHttpSettings $apimPoolManagementSetting -Priority 30

# Create the SKU and configure WAF mode
$sku = New-AzApplicationGatewaySku -Name "WAF_v2" -Tier "WAF_v2" -Capacity 2
$config = New-AzApplicationGatewayWebApplicationFirewallConfiguration -Enabled $true -FirewallMode "Prevention"
$policy = New-AzApplicationGatewaySslPolicy -PolicyType Predefined -PolicyName AppGwSslPolicy20220101

# Create the Application Gateway
$appgwName = "apim-app-gw"
$appgw = New-AzApplicationGateway -Name $appgwName -ResourceGroupName $resGroupName -Location $location `
  -BackendAddressPools $apimGatewayBackendPool,$apimPortalBackendPool,$apimManagementBackendPool `
  -BackendHttpSettingsCollection $apimPoolGatewaySetting, $apimPoolPortalSetting, $apimPoolManagementSetting `
  -FrontendIpConfigurations $fipconfig01 -GatewayIpConfigurations $gipconfig -FrontendPorts $fp01 `
  -HttpListeners $gatewayListener,$portalListener,$managementListener `
  -RequestRoutingRules $gatewayRule,$portalRule,$managementRule `
  -Sku $sku -WebApplicationFirewallConfig $config -SslCertificates $certGateway,$certPortal,$certManagement `
  -TrustedRootCertificate $trustedRootCert -Probes $apimGatewayProbe,$apimPortalProbe,$apimManagementProbe `
  -SslPolicy $policy

# After the application gateway deploys, confirm the health status of the API Management back ends
Get-AzApplicationGatewayBackendHealth -Name $appgwName -ResourceGroupName $resGroupName

# CNAME the API Management proxy hostname to the public DNS name of the Application Gateway resource
Get-AzPublicIpAddress -ResourceGroupName $resGroupName -Name "pip-appgateway"