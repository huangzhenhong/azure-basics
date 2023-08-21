Set-Variable -Name "ResourceGroupName" -Value "$(RG-METRIQ)"
Set-Variable -Name "AppServiceName" -Value "$(WebJobHostAppServiceName)"
Set-Variable -Name "WebJobName" -Value "$(WebJobName)"

# Start WebJob
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