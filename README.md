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

### Key Components in the solution

- Azure App Service and App plan exposing applications (Azure Functions)
- Monitoring of the solution with Azure Log Analytics Workspace, Azure Application Insights and Azure Monitor as tools for monitoring, security and audit
- Azure SQL Database as backend application database for the solution
- Azure Key Vault to store secrets and credentials for the solution
- Azure Storage to provide application storage for the solution
- Backend Virtual Network with monitoring and network security groups to protect backend resources (Key Vault, Storage, SQL)
- Private Links integrated with backend VNET to protect backend resources (Key Vault, Storage, SQL)
- Azure storage to store diagnostics and audit information

## Deployment

Deployment of Azure Application Workspace can be done through provided Azure Resource Manager [AAPPW.bicep](DeploymentScripts/AAPPW.bicep) file or via generated Azure Resource Manager Template file [AAPPW.json](DeploymentScripts/AAPPW.json) which itself is based on ARM Bicep file.

You can find those script files in [DeploymentScripts](DeploymentScripts) directory.

Deployment file will provision resources which are part of Azure Application Workspace.

### Deployment Example

```bash
az group create --name AAPPW --location NorthEurope --tags Costcenter=ABC001 Owner='Bob' --subscription "Subscription001"

az deployment group create -n AAPPW -g AAPPW -f AAPPW.bicep --parameters projectPrefix=proj01 securityOwnerAADLogin=aappwAdmin@xyz.com securityOwnerAADId=00000000-0000-0000-0000-000000000000 securityAlertEmail=aappwAdmin@xyz.com sqlServerLogin=myUserName sqlServerPassword=myPassword --subscription "Subscription001"
```

### Deployment parameters

Following parameters can be / must be passed into template file to provision environment with specific values.

- ```projectPrefix``` - required - Prefix for a project resources.
Each provisioned resource will use this prefix. This is for sorting / searching resources mainly.

- ```securityOwnerAADLogin``` - required - Specifies the login ID (Login Name) of a user in the Azure Active Directory tenant.
Resources which support Azure Active Directory for Authentication (like Azure SQL Database) will use
such specified account and assign this account into Administrator role.
This account is ultimate owner of the solution with the highest permissions.

- ```securityOwnerAADId``` - required - Specifies the login ID (Object ID) of a user in the Azure Active Directory tenant.
This is ID of the user which must correspond to the parameter ```securityOwnerAADLogin```.
Resources which support Azure Active Directory for Authentication (like Azure Key Vault) will use
such specified ID and assign this account into Administrator role.
This account is ultimate owner of the solution with the highest permissions.

- ```securityAlertEmail``` - required - Specifies the customer's email address where any security findings will be sent for further review.
This is mainly for any potential and suspicious security issues which should be further investigated.
Based on Azure Alert Policies and Azure Vulnerability Assessments on Azure SQL Database.

- ```sqlServerLogin``` - required - Specifies the Administrator login for SQL Server.
Azure SQL Database requires SQL Database Authentication (Username and password) be specified even though
Azure Active Directory is enabled.
This will be changed in the future and only Azure Active Directory will be enabled for Authentication.

- ```sqlServerPassword``` - required - Specifies the Administrator password for SQL Server.
Azure SQL Database requires SQL Database Authentication (Username and password) be specified even though
Azure Active Directory is enabled.
This will be changed in the future and only Azure Active Directory will be enabled for Authentication.

- ```location``` - optional - Target region/location for deployment of resources. Default value is taken from the target resource group location.

- ```resourceTags``` - optional - Tags to be associated with deployed resources. Default tags are taken from the target resource group.

- ```vNetPrefix``` - optional - This is virtual network address space range for the solution. Default value is 192.168.0.0/16.
If this VNET needs to be peered and/or routed through Enterprise Firewall, make sure the address space is not in the collision with
existing networks or provide other non-collision value. This VNET hosts at least two subnets.

- ```subnetAppServicePrefix``` - optional - This is subnet range from virtual network address space above
for App Service component. Default value is 192.168.0.0/21. Should not be smaller than /26.

- ```subnetPrivateLinkPrefix``` - optional - This is subnet range from virtual network address space above
for hosting private link resources. Default value is 192.168.8.0/21. Should not be smaller than /26.

- ```logRetentionInDays``` - optional - This value specifies for how long diagnostics, audit, security logs for Azure resources
should be kept in Log Analytics Workspace. Long retention period can have cost impact. Default value is 120 days.

- ```securityEmailAdmins``` - optional - Specifies if the security alert / security findings will be sent to the
Azure subscription administrators in an addition to the email in ```securityAlertEmail``` parameter. Default value is false.

- ```sqlServerDBSkuName``` - optional - Specifies the SKU for Azure SQL Database. Typically, a letter + Number code. S0 - S12, P1 - P15. Default value is S0.

- ```sqlServerDBTierName``` - optional - Specifies the tier or edition for Azure SQL Database. Basic, Standard, Premium. Default value is Standard.

- ```appSvcPlanSkuName``` - optional - Specifies the SKU for App Service Plan. Typically a letter + Number code. S0 - S3, P1 - P3. Default value is S2.
