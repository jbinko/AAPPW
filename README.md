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
