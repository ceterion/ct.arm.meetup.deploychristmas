# Simple Deployment Template

This Template is generated using Visual Studio Code arm Snippets
It can be used withoutany parameters. However, the target resource group must be created in advance and all properties are static.

## Snippets

`arm!` - Resource template skeleton

`arm-vm-windows` - Windows VM Template featuring

+ Virtual Network
+ Public IP
+ Diagnostics Storage Account
+ Virtual Machine
+ Diagnostics Extension

## Properties

After using the VM Snippet, most Parameters to be changed become highlighted and can be replaced at once.
>**Caution** only use lower case letters and numbers here, since there are some resources that won't accept other signs. (like the storage account)

### Other properties to change

| Name | Comments |
| ---- | -------- |
| adminUsername | string |
| adminPassword | Must match Windows Password complexity requirements |

## Resource Naming conventions

Some resources need to have unique names across subscriptions, regions or even globally
A storage account for example always comes along with a public DNS Name. Therefore it must be unique.

Microsoft gives a good overview about naming conventions with the following article:
<https://docs.microsoft.com/en-us/azure/architecture/best-practices/naming-conventions>