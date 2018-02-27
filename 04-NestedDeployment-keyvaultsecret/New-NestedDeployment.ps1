#Requires -Version 3.0
#Requires -Module AzureRM.Resources
#Requires -Module Azure.Storage
#Requires -Module @{ModuleName="AzureRm.Profile";ModuleVersion="3.0"}


Param(
    [string] $ArtifactStagingDirectory = $PSScriptRoot,
    [switch] $UploadArtifacts = $true,
    [string] $StorageAccountName,
    [string] $StorageContainerName = $(Split-Path $PSScriptRoot -Leaf).ToLowerInvariant() + '-stageartifacts',
    [string] $TemplateFile = $ArtifactStagingDirectory + '\azuredeploy.json',
    [string] $TemplateParametersFile = $ArtifactStagingDirectory + '\azuredeploy.parameters.json',
    [string] $DSCSourceFolder = $ArtifactStagingDirectory + '\DSC',
    [switch] $ValidateOnly,
    [string] $DebugOptions = "All",
    [switch] $Dev
)

try {
    [Microsoft.Azure.Common.Authentication.AzureSession]::ClientFactory.AddUserAgent("AzureQuickStarts-$UI$($host.name)".replace(" ","_"), "1.0")
} catch { }

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

function Format-ValidationOutput {
    param ($ValidationOutput, [int] $Depth = 0)
    Set-StrictMode -Off
    return @($ValidationOutput | Where-Object { $_ -ne $null } | ForEach-Object { @('  ' * $Depth + ': ' + $_.Message) + @(Format-ValidationOutput @($_.Details) ($Depth + 1)) })
}

$OptionalParameters = New-Object -TypeName Hashtable
$TemplateArgs = New-Object -TypeName Hashtable

if ($Dev) {
    $TemplateParametersFile = $TemplateParametersFile.Replace('azuredeploy.parameters.json', 'azuredeploy.parameters.dev.json')
    if (!(Test-Path $TemplateParametersFile)) {
        $TemplateParametersFile = $TemplateParametersFile.Replace('azuredeploy.parameters.dev.json', 'azuredeploy.parameters.1.json')
    }
}

Write-Host "Using parameter file: $TemplateParametersFile"

if (!$ValidateOnly) {
    $OptionalParameters.Add('DeploymentDebugLogLevel', $DebugOptions)
}

$TemplateFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateFile))
$TemplateParametersFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateParametersFile))

if ($UploadArtifacts) {
    # Convert relative paths to absolute paths if needed
    $ArtifactStagingDirectory = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $ArtifactStagingDirectory))
    $DSCSourceFolder = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $DSCSourceFolder))

    # Parse the parameter file and update the values of artifacts location and artifacts location SAS token if they are present
    $JsonParameters = Get-Content $TemplateParametersFile -Raw | ConvertFrom-Json
    if (($JsonParameters | Get-Member -Type NoteProperty 'parameters') -ne $null) {
        $JsonParameters = $JsonParameters.parameters
    }
    # Get location 
    $ResourceGroupLocation = $JsonParameters | Select-Object -Expand 'location' -ErrorAction Ignore | Select-Object -Expand 'value' -ErrorAction Ignore

    $ArtifactsLocationName = '_artifactsLocation'
    $ArtifactsLocationSasTokenName = '_artifactsLocationSasToken'
    $OptionalParameters[$ArtifactsLocationName] = $JsonParameters | Select-Object -Expand $ArtifactsLocationName -ErrorAction Ignore | Select-Object -Expand 'value' -ErrorAction Ignore
    $OptionalParameters[$ArtifactsLocationSasTokenName] = $JsonParameters | Select-Object -Expand $ArtifactsLocationSasTokenName -ErrorAction Ignore | Select-Object -Expand 'value' -ErrorAction Ignore

    # Create DSC configuration archive
    if (Test-Path $DSCSourceFolder) {
        $DSCSourceFilePaths = @(Get-ChildItem $DSCSourceFolder -File -Filter '*.ps1' | ForEach-Object -Process {$_.FullName})
        foreach ($DSCSourceFilePath in $DSCSourceFilePaths) {
            $DSCArchiveFilePath = $DSCSourceFilePath.Substring(0, $DSCSourceFilePath.Length - 4) + '.zip'
            Publish-AzureRmVMDscConfiguration $DSCSourceFilePath -OutputArchivePath $DSCArchiveFilePath -Force -Verbose
        }
    }

    # Create a storage account name if none was provided
    if ($StorageAccountName -eq '') {
        $StorageAccountName = 'stage' + ((Get-AzureRmContext).Subscription.Id).Replace('-', '').substring(0, 19)
    }
    
    $StorageResourceGroupName = 'ARM_Deploy_Staging'
    $StorageAccount = (Get-AzureRmStorageAccount | Where-Object{$_.StorageAccountName -eq $StorageAccountName})


    # Create the storage account if it doesn't already exist
    if ($StorageAccount -eq $null) {
        
        New-AzureRmResourceGroup -Location "$ResourceGroupLocation" -Name $StorageResourceGroupName -Force
        $StorageAccount = New-AzureRmStorageAccount -StorageAccountName $StorageAccountName -Type 'Standard_LRS' -ResourceGroupName $StorageResourceGroupName -Location "$ResourceGroupLocation"
    }

    # Generate the value for artifacts location if it is not provided in the parameter file
    if ($OptionalParameters[$ArtifactsLocationName] -eq $null) {
        $OptionalParameters[$ArtifactsLocationName] = $StorageAccount.Context.BlobEndPoint + $StorageContainerName
    }

    # Copy files from the local storage staging location to the storage account container
    New-AzureStorageContainer -Name $StorageContainerName -Context $StorageAccount.Context -ErrorAction SilentlyContinue *>&1

    $ArtifactFilePaths = Get-ChildItem $ArtifactStagingDirectory -Recurse -File | ForEach-Object -Process {$_.FullName}
    foreach ($SourcePath in $ArtifactFilePaths) {
       Set-AzureStorageBlobContent -File $SourcePath -Blob $SourcePath.Substring($ArtifactStagingDirectory.length + 1) -Container $StorageContainerName -Context $StorageAccount.Context -Force
    }
    # Generate a 4 hour SAS token for the artifacts location if one was not provided in the parameters file
    if ($OptionalParameters[$ArtifactsLocationSasTokenName] -eq $null) {
        $OptionalParameters[$ArtifactsLocationSasTokenName] = (New-AzureStorageContainerSASToken -Container $StorageContainerName -Context $StorageAccount.Context -Permission r -ExpiryTime (Get-Date).AddHours(4))
    }

    $TemplateArgs.Add('TemplateFile', $OptionalParameters[$ArtifactsLocationName] + "/" + (Get-ChildItem $TemplateFile).Name + $OptionalParameters[$ArtifactsLocationSasTokenName])

    $OptionalParameters[$ArtifactsLocationSasTokenName] = ConvertTo-SecureString $OptionalParameters[$ArtifactsLocationSasTokenName] -AsPlainText -Force

}
else {

    $TemplateArgs.Add('TemplateFile', $TemplateFile)

}

$TemplateArgs.Add('TemplateParameterFile', $TemplateParametersFile)

# Create or update the resource group using the specified template file and template parameters file
$ResourceGroups = $JsonParameters.ResourceGroups | Select-Object -ExpandProperty value
foreach($ResourceGroup in $ResourceGroups.psobject.properties.value){
    New-AzureRmResourceGroup -Name $ResourceGroup -Location $ResourceGroupLocation -Verbose -Force -ErrorAction Stop 
}

if ($ValidateOnly) {
    $ErrorMessages = Format-ValidationOutput (Test-AzureRmResourceGroupDeployment -ResourceGroupName $StorageResourceGroupName `
                                                                                  @TemplateArgs `
                                                                                  @OptionalParameters)
    if ($ErrorMessages) {
        Write-Output '', 'Validation returned the following errors:', @($ErrorMessages), '', 'Template is invalid.'
    }
    else {
        Write-Output '', 'Template is valid.'
    }
}
else {
    $OptionalParameters.add('DeploymentMode','Prepare')
    
    New-AzureRmResourceGroupDeployment -Name ((Get-ChildItem $TemplateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
                                       -ResourceGroupName $StorageResourceGroupName `
                                       @TemplateArgs `
                                       @OptionalParameters `
                                       -Force -Verbose `
                                       -ErrorVariable ErrorMessages
    if ($ErrorMessages) {
        Write-Output '', 'Template deployment returned the following errors:', @(@($ErrorMessages) | ForEach-Object { $_.Exception.Message.TrimEnd("`r`n") })
    }

    $OptionalParameters['DeploymentMode'] = 'Full'
    
    New-AzureRmResourceGroupDeployment -Name ((Get-ChildItem $TemplateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
                                       -ResourceGroupName $StorageResourceGroupName `
                                       @TemplateArgs `
                                       @OptionalParameters `
                                       -Force -Verbose `
                                       -ErrorVariable ErrorMessages
    if ($ErrorMessages) {
        Write-Output '', 'Template deployment returned the following errors:', @(@($ErrorMessages) | ForEach-Object { $_.Exception.Message.TrimEnd("`r`n") })
    }
}