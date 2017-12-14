$Location = "westeurope"


$VMSizes = Get-AzureRmVMSize -Location $Location
$Publishers = Get-AzureRmVMImagePublisher -Location $Location #check all the publishers available
$ImageOffers = Get-AzureRmVMImageOffer -Location $Location -PublisherName "MicrosoftWindowsServer" #look for offers for a publisher
$ImageSku = Get-AzureRmVMImageSku -Location $Location -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" #view SKUs for an offer
$VMImages = Get-AzureRmVMImage -Location $Location -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2012-R2-Datacenter" #pick one!