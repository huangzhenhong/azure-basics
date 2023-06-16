$SubscriptionId = "4cac86b0-1e56-bbbb-aaaa-000000000000"

$ResourceGroupName = "resourceGroupName"
$Location = "Japan West"

$ServerName = "serverName"
$DatabaseName = "databaseName"

$NewEdition = "Standard"
$NewPricingTier = "S2"

Add-AzureRmAccount
Select-AzureRmSubscription -SubscriptionId $SubscriptionId

$ScaleRequest = Set-AzureRmSqlDatabase -DatabaseName $DatabaseName -ServerName $ServerName -ResourceGroupName $ResourceGroupName -Edition $NewEdition -RequestedServiceObjectiveName $NewPricingTier

$ScaleRequest