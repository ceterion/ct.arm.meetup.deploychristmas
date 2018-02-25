# Azure Infrastructure Resource Template Tricks

![Deploy Christmas](https://raw.githubusercontent.com/ceterion/ct.arm.meetup.deploychristmas/master/03-NestedDeployment/CustomScripts/resources/deployazure.png)

## Overview

This session gives an overview to the most commonly used Azure Resources to build IaaS Environments. It is divided into the following three parts, each a little more complex.

### 01-SimpleDeployment

This template is generated from Scratch using Visual Studio Code Azure Resource Manager Snippets Plugin and is deployed with a very basic command without using any parameters.

### 02 KeyVault

KeyVaults are an essential component to each arm Deployment, because they eliminate the necessity to store Passwords within your Templates or parameter files.
The template in this Demo is a little bit modified to create an access Rule which permits the user executing the deployment to access all Secrets and Keys.
It also deploys a secret as prerequisite for the next part.

### 03 NestedDeployment (Cross-Resource-Group)

This part shows a more complex scenario including Cross Resource Group Nested Deploymnents and Utilization of many different Resource Manager Functions. Therefore, a slightly modified version of the [Deploy-AzureResourceGroup.ps1](https://github.com/Azure/azure-quickstart-templates/blob/master/Deploy-AzureResourceGroup.ps1) script from the Azure Quickstart Templates Repository.

> **Important:** In order to deploy part 3, make sure you created a keyvault first. Name and Secret Name must match the ones in this template

The following Resources are created:

1. Resource Group Network
   * a simple virtual Network with one subnet

2. Resource Group Monitoring
    * Storage Account used for Bootdiagnostics Data

3. Resource Group webservers
    * 1 load Balancer with public IP
    * 1 Availability Set
    * 1-n of the following
    * Network Interface connected to the Load Balancer Backend Pool
    * VM with managed Disk and CustomScript Extension