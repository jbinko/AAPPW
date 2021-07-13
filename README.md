# Azure Application Workspace (AAPPW) - Reference Architecture 2021 for Regulated Industries

## Project Overview

The goal of this project is to provide and document referential infrastructure architecture pattern,
guidance, explanations, and deployment resources/tools
to successfully deploy workspace for Azure application services.

Focus is to provide the highest security level as this deployment pattern is
used in Highly Regulated Industries.

For more details see: [Web app private connectivity](https://docs.microsoft.com/en-us/azure/architecture/example-scenario/private-web-app/private-web-app)

We are describing reusable pattern which can be further customized as each customer has different needs
and expectations. All resources are included inside this repository and we are open for feedback to further extend this pattern.

You can think about this guidance as Enterprise Ready plug-able
infrastructure building block for Application workloads compatible with Microsoft Best Practices for Landing Zones.

Application Workspace can be deployed multiple times in organization
for different teams, for different projects, for different environments (DEV, TEST, PROD, etc.).

Application Workspace can be deployed in automated way through provided scripts in cloud native way.
This provides consistent experience with focus on high quality security standards.
Approve once, deploy multiple times in the same secure way.

### Key Features

- Focus on Enterprise Grade Security standards
- Strong Support for Auditing, Monitoring and Diagnostics data
- Integrate and Keep network communication in perimeter where applicable
- Benefit from Cloud Managed Services, reduce management and operations overhead
- Integrations with other cloud native tools
- Protect and encrypt storage where potentially sensitive data are stored
- Protect keys and credentials in secure place

## Deployment

Deployment of Azure Application Workspace can be done through provided Azure Resource Manager [AAPPW.bicep](DeploymentScripts/AAPPW.bicep) file or via generated Azure Resource Manager Template file [AAPPW.json](DeploymentScripts/AAPPW.json) which itself is based on ARM Bicep file.

You can find those script files in [DeploymentScripts](DeploymentScripts) directory.

Deployment file will provision resources which are part of Azure Application Workspace.

### Deployment Example

```bash
az group create --name AAPPW --location NorthEurope --tags Costcenter=ABC001 Owner='Bob' --subscription "Subscription001"

az deployment group create -n AAPPW -g AAPPW -f AAPPW.bicep --parameters projectPrefix=proj01 securityOwnerAADLogin=aappwAdmin@xyz.com securityOwnerAADId=00000000-0000-0000-0000-000000000000 securityAlertEmail=aappwAdmin@xyz.com sqlServerLogin=myUserName sqlServerPassword=myPassword --subscription "Subscription001"
```
