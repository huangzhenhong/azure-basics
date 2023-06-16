# Write your PowerShell commands here.

Write-Host "Set username and password for SQL connection"

# get parameters from Azure Devops
Write-Host "##vso[task.setvariable variable=SqlLoginUser;]$SqlLoginUser"
Write-Host "##vso[task.setvariable variable=SqlLoginPassword;]$SqlLoginPassword"

# Updating files in the artifacts
$filePath = '$(System.DefaultWorkingDirectory)/_Dev/drop/Src/Specs/IntegrationTesting/'
Write-Host "Replacing SQL Secrets"
$files = Get-ChildItem -Include *.jmx -File -Recurse -Path $filePath
foreach($file in $files) {
    Write-Host $file
    $doc = New-Object System.Xml.XmlDocument
    $doc.PreserveWhitespace = $true
    $doc.Load($file)
    $nodes = $doc.SelectNodes('/jmeterTestPlan/hashTree/hashTree/JDBCDataSource/stringProp')
    foreach($node in $nodes)
    {
        # Write-Host $node.name
        if($node.name -eq 'password'){
            Write-Host $node.name
            Write-Host $node.InnerText
            $node.InnerText = $SqlLoginPassword
        }
        if($node.name -eq 'username') {
            Write-Host $node.name
            Write-Host $node.InnerText
            $node.InnerText = $SqlLoginUser
        }
    }
    $doc.Save($file)
}