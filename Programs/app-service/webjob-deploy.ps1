# https://github.com/Azure/azure-powershell/blob/main/src/Websites/Websites/help/Publish-AzWebApp.mdc
# https://learn.microsoft.com/en-us/powershell/module/az.websites/publish-azwebapp?view=azps-10.2.0

param
(
    [string] $buildOutput = $(throw "Directory with build output is required"),
    [string] $resourceGroupName = $(throw "Resource group name is required"),
    [string] $webAppName = $(throw "Web app name is required"),
    [string] $webJobName = $(throw "Web job name is required"),
    [string] $webJobType = "triggered"
)

# Connect-AzAccount -TenantId ''
# Select-AzSubscription -SubscriptionId ''
# $buildOutput = '$(System.DefaultWorkingDirectory)/_Release/WebAPI/RegistryJobsOkta'
# $resourceGroupName = 'PENTEST-REGIONAL-EASTUS2-METRIQ-RG'
# $webAppName = 'PENTEST-REGIONAL-EASTUS2-METRIQ-OKTASYNC-ASE'
# $webJobName = 'OktaSync'
# $webJobType = 'Continuous'
# $buildOutput = "$currentDir\RegistryJobsOkta"

$currentDir = (Get-Item .).FullName
$tempDir = "$currentDir\Temp"
$webJobDir = "$tempDir\App_Data\jobs\$webJobType\$webJobName"

New-Item $webJobDir -ItemType Directory
Copy-Item "$buildOutput\*" -Destination $webJobDir -Recurse
Compress-Archive -Path "$tempDir\*" -DestinationPath ".\$webJobName.zip"
Remove-Item $tempDir -Recurse -Force

# az webapp deployment source config-zip -g $resourceGroupName -n $webAppName --src "$webJobName.zip"
Publish-AzWebApp -ResourceGroupName $resourceGroupName -Name $webAppName -ArchivePath "$webJobName.zip" -Force



