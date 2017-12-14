New-AzureRmResourceGroup -name "ff-test-01" -Location "westeurope"
New-AzureRmResourceGroupDeployment -ResourceGroupName "ff-test-01" -TemplateFile ".\01-SimpleDeployment\deploytemplate.json"