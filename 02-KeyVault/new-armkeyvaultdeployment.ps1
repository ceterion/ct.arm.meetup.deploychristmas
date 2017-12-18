
$resourcegroupname = "securitydata"

$Parameters = New-Object -TypeName Hashtable

# Get current AzureContext Account ID 
$CurrentAccountID = (Get-AzureRmADUser -defaultprofile (Get-AzureRmcontext)).id.tostring()
$Parameters.Add('AccountID', $CurrentAccountID)
$Parameters.Add('keyVaultName', 'ffmeetup-DeploymentVault')
$Parameters.Add('secretname', 'AdminLocal')

New-AzureRmResourceGroup -name $resourcegroupname -Location "westeurope"
New-AzureRmResourceGroupDeployment -ResourceGroupName $resourcegroupname `
                                    -TemplateFile ".\02-Keyvault\keyvault.json" `
                                    @Parameters `
                                    -force -verbose `
                                    -ErrorVariable ErrorMessages


if ($ErrorMessages) {
    Write-Output '', 'Template deployment returned the following errors:', @(@($ErrorMessages) | ForEach-Object { $_.Exception.Message.TrimEnd("`r`n") })
}
