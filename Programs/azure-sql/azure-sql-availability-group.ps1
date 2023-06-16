# Do a general Internet search for "Tutorial: Implement a geo-distributed database (Azure SQL Database)" for more information

# Sign in to Azure account
Connect-AzAccount

# Replace all values in <brackets> with your own values. Remove the brackets but leave the quotation marks

# Declare variables
$admin = "<DesiredAdminName>"
$password = "<DesiredPassword>"
$resourceGroup = "<YourExistingResourceGroup>"
$rglocation = "<YourResourceGroupLocation>"
$primaryServer = "<YourExistingDatabaseServer>"
$database = "<YourExistingDatabase>"
$backupLocation = "<YourDesiredLocation>" #This is the location for the backup server, so it must be in a different location than the (existing) primary server
$backupServer = "<DesiredBackupServerName>"
$failoverGroup = "<DesiredFailoverGroupName>" #Must be globally unique


# Create a backup server in the failover region
New-AzSqlServer -ResourceGroupName $resourceGroup -ServerName $backupServer -Location $backupLocation -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $admin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))


# Create a failover group containing the primary and backup servers
New-AzSqlDatabaseFailoverGroup –ResourceGroupName $resourceGroup -ServerName $primaryServer -PartnerServerName $backupServer –FailoverGroupName $failoverGroup –FailoverPolicy Automatic -GracePeriodWithDataLossHours 1

<#The GracePeriodWithDataLossHours parameter controls how long the system waits before failover occurs in case of an outage. 
  If, for example, the value is 1 (hour), then the system will initiate failover after an hour. 
  It is possible for data loss to occur during the failover process, so by specifying this value, if the 
  outage is recoverable within that period of time,  then failover will not occur, and therefore no data loss will occur.
  This parameter is optional.#>


# Add the database to the failover group
Get-AzSqlDatabase -ResourceGroupName $resourceGroup -ServerName $primaryServer -DatabaseName $database | Add-AzSqlDatabaseToFailoverGroup -ResourceGroupName $resourceGroup -ServerName $server -FailoverGroupName $failoverGroup


# Verify the failover group properties
Get-AzSqlDatabaseFailoverGroup -ResourceGroupName $resourceGroup -ServerName $primaryServer #You can use the variable for either server here, the primary or the backup


# Verify the current role of the backup server (should be "secondary")
(Get-AzSqlDatabaseFailoverGroup -FailoverGroupName $failoverGroup -ResourceGroupName $resourceGroup -ServerName $backupServer).ReplicationRole


# Initiate a manual failover
Switch-AzSqlDatabaseFailoverGroup -ResourceGroupName $resourceGroup -ServerName $backupServer -FailoverGroupName $failoverGroup


# Verify the current role again (should be "primary")


# Initiate a manual failback
Switch-AzSqlDatabaseFailoverGroup -ResourceGroupName $resourceGroup -ServerName $primaryServer -FailoverGroupName $failoverGroup


# Verify the current role again (should be back to "secondary")


# Failover group created and tested!


#Cleanup - I have encountered some token expiry errors when trying to run these commands within the same session as creating everything originally, I recommend that you sign out of the previous session and log back in if that happens.
# I also created new variables in the new session for the Get-AzSqlServer cmdlet, and used explicit names for parameter values just to be sure everything was being referenced correctly

#Remove all databases from the failover group
$priServer = Get-AzSqlServer -ResourceGroupName <YourExistingResourceGroup> -ServerName <YourExistingDatabaseServer>
$fg = $priServer | Remove-AzSqlDatabaseFromFailoverGroup -FailoverGroupName <DesiredFailoverGroupName> -Database ($priServer | Get-AzSqlDatabase)

#Remove the failover group
Remove-AzSqlDatabaseFailoverGroup -ResourceGroupName <YourExistingResourceGroup> -ServerName <YourExistingDatabaseServer> -FailoverGroupName <DesiredFailoverGroupName>

#Remove the backup server
Remove-AzSqlServer -ResourceGroupName <YourExistingResourceGroup> -ServerName <DesiredBackupServerName>