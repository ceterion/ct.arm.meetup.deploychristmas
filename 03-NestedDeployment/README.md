# Nested Cross Resource Group Deployment

## Deployment Script

<details>
<summary>Modifications</summary>
<p>

The deployment Script used in this example is derived from the one fond in the Azure Quickstart Templates Repository
<https://github.com/Azure/azure-quickstart-templates/blob/master/Deploy-AzureResourceGroup.ps1>

The following modifications have been implemented to work with cross resource group deployments found here

+ Resource Groups in azuredeploy.parameters.json are taken to pre-create resource groups before initiating the actual deployment
+ Resource location is taken from parameters file
+ [deprecated] tried to get account that is executing the deployment to set keyvault access policies 


see also
<https://github.com/ceterion/ct.arm.meetup.deploychristmas/commit/8d92e0f17b142fcc02e662ffd270b929461ff531#diff-28d99a324e59844e379c85ad9cb29987>

</p>
</details>

## Snippets used in this template

<details>
<summary>Keep Passwords secure by using Key Vault in your Deployment</summary>
<p>

```json
{
    "VMAdminUserName": { "value": "AdminLocal" },
    "VMAdminPassword": {
        "reference": {
            "keyVault": {
                "id": "[concat('/subscriptions/', subscription().subscriptionId, '/resourcegroups/', parameters('ResourceGroups').KeyVault, '/providers/Microsoft.KeyVault/vaults/',variables('keyvaultname'))]"
            },
            "secretName": "AdminLocal"
    }
}
```

<https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-manager-keyvault-parameter>

</p>
</details>
<details>
<summary>Organize Resources with Tags</summary>
<p>

Tagging resources offers a broad range of advantages.
It can be utilized by Automation jobs to target a group of machines in order to do stuff like shutting them down or get insight on consumption.

Microsoft gives some good advice on that topic which can be found within their best practices/naming conventions article
<https://docs.microsoft.com/en-us/azure/architecture/best-practices/naming-conventions#organize-resources-with-tags>

In addition, tagging is very easy. Here is an example:

```json
{
            "apiVersion": "2017-03-30",
            "type": "Microsoft.Compute/virtualMachines",
            "name": "[parameters('VMName')]",
            "tags":{
                "displayname": "VM",
                "Service": "[parameters('ServiceName')]"
            },
            "location": "[resourceGroup().location]",
```

</p>
</details>
<details>
<summary>cross resource group deployment</summary>
<p>

In a nested Deployment, it is possible to distribute your resources to different resource groups using the "ResourceGroup" property which is available to the "deployments" resource

```json
{
    "name": "Network",
    "type": "Microsoft.Resources/deployments",
    "apiVersion": "[variables('deploymentsapiVersion')]",
    "ResourceGroup": "[parameters('ResourceGroups').Network]",
    "dependsOn": [],
    "properties": {
        "mode": "Incremental",
        "templateLink": {
        "uri": "[variables('NetworkTemplateURI')]",
        "contentVersion": "1.0.0.0"
        },
        "parameters": {
        "NetworkName": { "value": "[parameters('NetworkName')]" },
        "NetworkAddressPrefixes": { "value": ["10.0.0.0/16"] } 
        }
    }
}
...
{           
    "condition": "[equals(parameters('DeploymentMode'),'Full')]",
    "name": "VM",
    "type": "Microsoft.Resources/deployments",
```

See <https://github.com/ceterion/ct.arm.meetup.deploychristmas/commit/73c26ea1a0967c8b46e299097425901612362d0d>

</p>
</details>

## Resource Template Functions

<details>
<summary>Concat</summary>
<p>

Concat is one of the most important and most used resource template function. It can be used to combine strings.
In the following example, it is used to dynamically reference a KeyVault 

```json
"[concat('/subscriptions/', subscription().subscriptionId, '/resourcegroups/', parameters('ResourceGroups').KeyVault, '/providers/Microsoft.KeyVault/vaults/',variables('keyvaultname'))]"
```

</p>
</details>
<details>
<summary>create fixed-length names with padleft</summary>
<p>

naming conventions most likely rely on a fixed length of names. Using functions like copyindex ufortunately returns integers, so if you always want a 2-digit number, just using the copyindex() function alone would not fulfill this criteria as long as the index is below 10.
you can overcome this using padleft() function. 

```json
padLeft(copyindex(),2,'0'))
```

the example above adds a leading '0' as long as the length of copyindex is below 2 digits

</p>
</details>
<details>
<summary>conditional deployment</summary>
<p>

For some time now, it is possible to use conditions within arm templates.
Thus, we are now able to deploy or skip resources based on parameter or variable values

```json
 {
    "DeploymentMode": {
        "type": "string",
        "metadata": {
        "description": "Determines, which Resources to deploy"
    }
},
...
{           
    "condition": "[equals(parameters('DeploymentMode'),'Full')]",
    "name": "VM",
    "type": "Microsoft.Resources/deployments",
```

See <https://github.com/ceterion/ct.arm.meetup.deploychristmas/commit/73c26ea1a0967c8b46e299097425901612362d0d>

</p>
</details>

