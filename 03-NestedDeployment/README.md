# Nested Cross Resource Group Deployment

## Keep Passwords secure by using Key Vault in your Deployment

```json
"VMAdminUserName": { "value": "AdminLocal" },
"VMAdminPassword": {
    "reference": {
        "keyVault": {
            "id": "[concat('/subscriptions/', subscription().subscriptionId, '/resourcegroups/', parameters('ResourceGroups').KeyVault, '/providers/Microsoft.KeyVault/vaults/',variables('keyvaultname'))]"
        },
        "secretName": "AdminLocal"
    }
},
```