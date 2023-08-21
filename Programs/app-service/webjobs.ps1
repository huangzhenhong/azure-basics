# Connect-AzAccount
# Add-AzureAccount

param (
    $SubscriptionId = "",
    $ResourceGroupName = 'DEV-REGIONAL-EASTUS2-METRIQ-RG',
    $WebJobName = 'OktaSync2',
    $AppServiceName = 'DEV-REGIONAL-EASTUS2-METRIQ-REGISTRYJOBOKTA-ASE'
)

Select-AzSubscription -SubscriptionId $SubscriptionId

$webjob = Get-AzWebAppContinuousWebJob -ResourceGroupName $ResourceGroupName -AppName $AppServiceName -Name $WebJobName
if($null -ne $webjob) {
    $status = $webjob | Select-Object -Property Status
    if($status.Status -eq "Stopped") {
        Start-AzWebAppContinuousWebJob -ResourceGroupName $ResourceGroupName -AppName $AppServiceName -Name $WebJobName
        Start-Sleep -Seconds 5
        $status = Get-AzWebAppContinuousWebJob -ResourceGroupName $ResourceGroupName -AppName $AppServiceName -Name $WebJobName | Select-Object -Property Status
        if($status.Status -eq "Running") {
            Write-Host "WebJob $($WebJobName) is started in resource group $($ResourceGroupName)"
        }else {
            Write-Host "Failed to start WebJob $($WebJobName) in resource group $($ResourceGroupName)"
        }
    }
}

$webjob = Get-AzWebAppContinuousWebJob -ResourceGroupName $ResourceGroupName -AppName $AppServiceName -Name $WebJobName
if($null -ne $webjob) {
    $status = $webjob | Select-Object -Property Status
    if($status.Status -eq "Running") {
        Stop-AzWebAppContinuousWebJob -ResourceGroupName $ResourceGroupName -AppName $AppServiceName -Name $WebJobName
        Start-Sleep -Seconds 5
        $status = Get-AzWebAppContinuousWebJob -ResourceGroupName $ResourceGroupName -AppName $AppServiceName -Name $WebJobName | Select-Object -Property Status
        if($status.Status -eq "Stopped") {
            Write-Host "WebJob $($WebJobName) is stopped in resource group $($ResourceGroupName)"
        }else {
            Write-Host "Failed to stop WebJob $($WebJobName) in resource group $($ResourceGroupName)"
        }
    }
}