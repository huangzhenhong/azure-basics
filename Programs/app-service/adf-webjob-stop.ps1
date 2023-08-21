Set-Variable -Name "ResourceGroupName" -Value "$(RG-METRIQ)"
Set-Variable -Name "AppServiceName" -Value "$(WebJobHostAppServiceName)"
Set-Variable -Name "WebJobName" -Value "$(WebJobName)"

# Stop WebJobs
# https://learn.microsoft.com/en-us/powershell/module/az.websites/stop-azwebappcontinuouswebjob?view=azps-10.2.0
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
