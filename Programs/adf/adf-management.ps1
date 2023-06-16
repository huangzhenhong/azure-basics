#Connect-AzAccount
#Get-AzSubscription 

param (
    $SubscriptionId = "",
    $ResourceGroupName = 'TEST-REGIONAL-EASTUS2-RG',
    $DataFactoryName = 'TEST-REGIONAL-EASTUS2-ADF',
    $TriggerName = 'ReportDbDataSyncScheduler',
    $PipelineName = 'DataSync'
)

Select-AzSubscription -SubscriptionId $SubscriptionId

Write-Host "Stopping scheduled trigger: $($TriggerName) in data factory: $($DataFactoryName)"

$trigger = Get-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $TriggerName

if($null -ne $trigger){
    $state = $trigger | Select-Object -Property RuntimeState

    if($state.RuntimeState -eq "Started") {
        $stopped = $trigger | Stop-AzDataFactoryV2Trigger -Force -Verbose
        if($true -eq $stopped) {
            Write-Host "Trigger: $($TriggerName) in data factory $($DataFactoryName) was stopped."
        }else {
            Write-Host "Can not stop the trigger: $($TriggerName) in data factory $($DataFactoryName)."
        }
    } else {
        Write-Host "Trigger: $($TriggerName) in data factory $($DataFactoryName) was stopped."
    }
} else {
    Write-Host "Trigger: $($TriggerName) in data factory $($DataFactoryName) was not found."
}

Write-Host "Cancelling all running pipelines in last 2 hours"

# Azure Data Factory is using Utc time
$startUtc = (Get-Date).AddHours(-2).ToUniversalTime()
$endUtc = (Get-Date).ToUniversalTime()

Get-AzDataFactoryV2PipelineRun -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -LastUpdatedAfter $startUtc -LastUpdatedBefore $endUtc |
Where-Object -Property Status -eq "InProgress" |
Select-Object -Property RunId |
ForEach-Object { 
    Get-AzDataFactoryV2PipelineRun -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -PipelineRunId $_.RunId | Stop-AzDataFactoryV2PipelineRun -Verbose
}

# Get-AzDataFactoryV2PipelineRun -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -PipelineRunId "18994d88-ed6f-4209-84dc-8df7983ebf0b"

# Stop-AzDataFactoryV2PipelineRun -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -PipelineRunId $_.RunId

# Start the trigger
# Get-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $TriggerName | Start-AzDataFactoryV2Trigger -Force

Write-Host "Starting scheduled trigger: $($TriggerName) in data factory: $($DataFactoryName)"

$started = Get-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $TriggerName | 
Where-Object -Property RuntimeState -eq "Stopped" | 
Start-AzDataFactoryV2Trigger -Force

if($true -eq $started) {
    Write-Host "Trigger: $($TriggerName) in data factory $($DataFactoryName) was started."
    $runId = Invoke-AzDataFactoryV2Pipeline -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -PipelineName $PipelineName -Verbose
    if($null -ne $runId) {
        Write-Host "Pipeline $($PipelineName) was triggered, Run Id: $($runId)"
    }
}else {
    Write-Host "Can not start the trigger: $($TriggerName) in data factory $($DataFactoryName)."
}

