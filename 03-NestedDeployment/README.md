# Nested Cross Resource Group Deployment

## Deployment Script

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
