

Get-AzureRmResourceProvider | Out-GridView
(Get-AzureRmResourceProvider -Location "westeurope").ResourceTypes | Out-GridView