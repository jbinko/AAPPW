// ----- PARAMETERS

@minLength(3)
@maxLength(7)
@description('Prefix for a project resources.')
param projectPrefix string

@minLength(1)
@description('Specifies the login ID (Login Name) of a user in the Azure Active Directory tenant.')
param securityOwnerAADLogin string

@minLength(1)
@description('Specifies the login ID (Object ID) of a user in the Azure Active Directory tenant.')
param securityOwnerAADId string

@minLength(5)
@description('Specifies the email address where security findings will be sent for further analysis.')
param securityAlertEmail string

@minLength(6)
@description('Specifies the Administrator login for SQL Server.')
param sqlServerLogin string

@minLength(12)
@secure()
@description('Specifies the Administrator password for SQL Server.')
param sqlServerPassword string

// Optional Parameter
@description('Target region/location for deployment of resources.')
param location string = resourceGroup().location

// Optional Parameter
@description('Tags to be associated with deployed resources.')
param resourceTags object = (contains(resourceGroup(), 'tags') ? resourceGroup().tags : {} )

// Optional Parameter
@description('Address space of the Virtual Network.')
param vNetPrefix string = '192.168.0.0/16'

// Optional Parameter
@description('Address space of the App Service subnet.')
param subnetAppServicePrefix string = '192.168.0.0/21'

// Optional Parameter
@description('Address space of the Private Link subnet.')
param subnetPrivateLinkPrefix string = '192.168.8.0/21'

// Optional Parameter
@description('Number of days for which to retain logs.')
param logRetentionInDays int = 120

// Optional Parameter
@description('Specifies if the security alert is sent to the account administrators.')
param securityEmailAdmins bool = false

// Optional Parameter
@description('Specifies the SKU for Azure SQL Database. Typically a letter + Number code. S0 - S12, P1 - P15.')
param sqlServerDBSkuName string = 'S0'

// Optional Parameter
@description('Specifies the tier or edition for Azure SQL Database. Basic, Standard, Premium.')
param sqlServerDBTierName string = 'Standard'

// Optional Parameter
@description('Specifies the SKU for App Service Plan. Typically a letter + Number code. S0 - S3, P1 - P3.')
param appSvcPlanSkuName string = 'S2'

// ----- VARIABLES

var lowerProjectPrefix = toLower(projectPrefix)

var plBlobDnsZone = 'privatelink.blob.core.windows.net'
var plKvDnsZone = 'privatelink.vaultcore.azure.net'
var plSqlDnsZone = 'privatelink.database.windows.net'

var laUniqueName = '${lowerProjectPrefix}-appsvc-la'

var vNetName = '${lowerProjectPrefix}-appsvc-vnet'
var vNetNsgFlowLogRetentionInDays = 31

var saDiagUniqueName = '${lowerProjectPrefix}appsvcdiagsa'
var saContentUniqueName = '${lowerProjectPrefix}appsvccontentsa'

var kvUniqueName = '${lowerProjectPrefix}-appsvc-kv'
var kvKeyPermissionsAll = [
  'backup'
  'create'
  'decrypt'
  'delete'
  'encrypt'
  'get'
  'import'
  'list'
  'purge'
  'recover'
  'restore'
  'sign'
  'unwrapKey'
  'update'
  'verify'
  'wrapKey'
]
var kvSecretsPermissionsAll = [
  'backup'
  'delete'
  'get'
  'list'
  'purge'
  'recover'
  'restore'
  'set'
]
var kvCertificatesPermissionsAll = [
  'backup'
  'create'
  'delete'
  'deleteissuers'
  'get'
  'getissuers'
  'import'
  'list'
  'listissuers'
  'managecontacts'
  'manageissuers'
  'purge'
  'recover'
  'restore'
  'setissuers'
  'update'
]
var kvStoragePermissionsAll = [
  'backup'
  'delete'
  'deletesas'
  'get'
  'getsas'
  'list'
  'listsas'
  'purge'
  'recover'
  'regeneratekey'
  'restore'
  'set'
  'setsas'
  'update'
]

var sqlServerUniqueName = '${lowerProjectPrefix}-appsvc-sql'
var sqlServerDBUniqueName = '${lowerProjectPrefix}-appsvc-sql-db'
// Keep weekly backups for 1 week
var sqlServerDBWeeklyRetention = 'P1W' // Valid value is between 1 to 520 weeks. e.g. P1Y, P1M, P1W or P7D.
// Keep the first backup of each month for 1 month
var sqlServerDBMonthlyRetention = 'P1M' // Valid value is between 1 to 120 months. e.g. P1Y, P1M, P4W or P30D.
// Keep an annual backup from 1st Week of the year for 5 years
var sqlServerDBYearlyRetention = 'P5Y' // Valid value is between 1 to 10 years. e.g. P1Y, P12M, P52W or P365D.
var sqlServerDBWeekOfYear = 1 // The week of year to take the yearly backup. Value has to be between 1 and 52.

var appSvcPlanUniqueName = '${lowerProjectPrefix}-appsvc-plan'
var appSvcInsightsUniqueName = '${lowerProjectPrefix}-appsvc-insights'
var appSvcFunctionUniqueName = '${lowerProjectPrefix}-appsvc-function'

// ----- PRIVATE LINK

resource plBlobZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: plBlobDnsZone
  location: 'global'
  tags: resourceTags
  properties: {}
}

resource plBlobZoneVNetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${plBlobDnsZone}/${plBlobDnsZone}'
  location: 'global'
  tags: resourceTags
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
    registrationEnabled: false
  }
}

resource plKVZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: plKvDnsZone
  location: 'global'
  tags: resourceTags
  properties: {}
}

resource plKVZoneVNetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${plKVZone.name}/${plKVZone.name}'
  location: 'global'
  tags: resourceTags
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
    registrationEnabled: false
  }
}

resource plSqlZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: plSqlDnsZone
  location: 'global'
  tags: resourceTags
  properties: {}
}

resource plSqlZoneVNetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${plSqlZone.name}/${plSqlZone.name}'
  location: 'global'
  tags: resourceTags
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
    registrationEnabled: false
  }
}

// ----- LOG ANALYTICS

resource la 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: laUniqueName
  tags: resourceTags
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
      //capacityReservationLevel: int
    }
    retentionInDays: logRetentionInDays
    /*workspaceCapping: {
      dailyQuotaGb: any('number')
    }*/
    publicNetworkAccessForIngestion: 'Enabled' // AppInsights can ingest over public EP
    publicNetworkAccessForQuery: 'Disabled'
  }
}

resource la_diagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'DiagnosticSettings'
  scope: la
  properties: {
    //storageAccountId:
    workspaceId: la.id
    // logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        category: 'Audit'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
    ]
  }
}

// ----- NETWORKING

resource nsgAppService 'Microsoft.Network/networkSecurityGroups@2020-08-01' = {
  name: '${lowerProjectPrefix}-appsvc-nsg'
  location: location
  tags: resourceTags
  properties: {
    securityRules:[
      {
        name: 'Deny-All-In'
        properties: {
          priority: 1000
          protocol: '*'
          direction: 'Inbound'
          access: 'Deny'
          description: 'Deny-All-In'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
      {
        name: 'Allow-AppService-443-Outbound'
        properties: {
          priority: 500
          protocol: 'Tcp'
          direction: 'Outbound'
          access: 'Allow'
          description: 'Allow-AppService-443-Outbound'
          sourceAddressPrefix: subnetAppServicePrefix
          sourcePortRange: '*'
          destinationAddressPrefix: subnetPrivateLinkPrefix
          destinationPortRange: '443'
        }
      }
      {
        name: 'Allow-AppService-1433-Outbound'
        properties: {
          priority: 600
          protocol: 'Tcp'
          direction: 'Outbound'
          access: 'Allow'
          description: 'Allow-AppService-1433-Outbound'
          sourceAddressPrefix: subnetAppServicePrefix
          sourcePortRange: '*'
          destinationAddressPrefix: subnetPrivateLinkPrefix
          destinationPortRange: '1433'
        }
      }
      {
        name: 'Deny-All-Out'
        properties: {
          priority: 1000
          protocol: '*'
          direction: 'Outbound'
          access: 'Deny'
          description: 'Deny-All-Out'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

resource nsgAppService_diagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'DiagnosticSettings'
  scope: nsgAppService
  properties: {
    //storageAccountId:
    workspaceId: la.id
    // logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        category: 'NetworkSecurityGroupEvent'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
      {
        category: 'NetworkSecurityGroupRuleCounter'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
    ]
    metrics: []
  }
}

resource nsgPrivateLink 'Microsoft.Network/networkSecurityGroups@2020-08-01' = {
  name: '${lowerProjectPrefix}-appsvc-nsg-private-link'
  location: location
  tags: resourceTags
  properties: {
    securityRules:[
      {
        name: 'Allow-AppService-443-Inbound'
        properties: {
          priority: 500
          protocol: 'Tcp'
          direction: 'Inbound'
          access: 'Allow'
          description: 'Allow-AppService-443-Inbound'
          sourceAddressPrefix: subnetAppServicePrefix
          sourcePortRange: '*'
          destinationAddressPrefix: subnetPrivateLinkPrefix
          destinationPortRange: '443'
        }
      }
      {
        name: 'Allow-AppService-1433-Inbound'
        properties: {
          priority: 600
          protocol: 'Tcp'
          direction: 'Inbound'
          access: 'Allow'
          description: 'Allow-AppService-1433-Inbound'
          sourceAddressPrefix: subnetAppServicePrefix
          sourcePortRange: '*'
          destinationAddressPrefix: subnetPrivateLinkPrefix
          destinationPortRange: '1433'
        }
      }
      {
        name: 'Deny-All-In'
        properties: {
          priority: 1000
          protocol: '*'
          direction: 'Inbound'
          access: 'Deny'
          description: 'Deny-All-In'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
      {
        name: 'Deny-All-Out'
        properties: {
          priority: 1000
          protocol: '*'
          direction: 'Outbound'
          access: 'Deny'
          description: 'Deny-All-Out'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

resource nsgPrivateLink_diagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'DiagnosticSettings'
  scope: nsgPrivateLink
  properties: {
    //storageAccountId:
    workspaceId: la.id
    // logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        category: 'NetworkSecurityGroupEvent'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
      {
        category: 'NetworkSecurityGroupRuleCounter'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
    ]
    metrics: []
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2020-07-01' = {
  dependsOn: [
    plBlobZone
    plKVZone
    plSqlZone
  ]
  name: vNetName
  location: location
  tags: resourceTags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNetPrefix
      ]
    }
    subnets: [
      {
        name: 'AppService'
        properties: {
          addressPrefix: subnetAppServicePrefix
          networkSecurityGroup: {
            id: nsgAppService.id
          }
          delegations: [
            {
              name: 'deleg-AppService'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: 'private-link'
        properties: {
          addressPrefix: subnetPrivateLinkPrefix
          networkSecurityGroup: {
            id: nsgPrivateLink.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
    enableVmProtection: true
  }
}

resource vnet_diagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'DiagnosticSettings'
  scope: vnet
  properties: {
    //storageAccountId:
    workspaceId: la.id
    // logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        category: 'VMProtectionAlerts'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
    ]
  }
}

module vnet_deployNSGFlowLogs './AAPPW.NSGFlowLogs.bicep' = {
  name: 'deployNSGFlowLogs'
  scope: resourceGroup('NetworkWatcherRG')
  params: {
    location: location
    tags: resourceTags
    storageId: sadiag.id
    workspaceId: la.properties.customerId
    workspaceRegion: la.location
    workspaceResourceId: la.id
    retentionInDays: vNetNsgFlowLogRetentionInDays
    nsgAppServiceId: nsgAppService.id
    nsgAppServiceName: nsgAppService.name
    nsgPrivateLinkId: nsgPrivateLink.id
    nsgPrivateLinkName: nsgPrivateLink.name
  }
}

// ----- STORAGE ACCOUNTS

resource sadiag 'Microsoft.Storage/storageAccounts@2021-01-01' = {
  name: saDiagUniqueName
  location: location
  tags: resourceTags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  identity:{
    type: 'SystemAssigned'
  }
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    isHnsEnabled: false
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices' // Required by SQL auditingSettings - https://docs.microsoft.com/en-us/azure/azure-sql/database/audit-write-storage-account-behind-vnet-firewall
    }
  }
}

resource sadiag_atp 'Microsoft.Security/advancedThreatProtectionSettings@2019-01-01' = {
  scope: sadiag
  name: 'current'
  properties: {
    isEnabled: true
  }
}

resource sadiag_privateLink 'Microsoft.Network/privateEndpoints@2020-08-01' = {
  name: '${saDiagUniqueName}-private-link'
  location: location
  tags: resourceTags
  properties: {
    subnet: {
      id: vnet.properties.subnets[1].id
    }
    privateLinkServiceConnections: [
      {
        name: '${saDiagUniqueName}-private-link'
        properties: {
          privateLinkServiceId: sadiag.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource sadiag_privateLink_zoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-08-01' = {
  name: '${sadiag_privateLink.name}/private-link'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: sadiag.name
        properties: {
          privateDnsZoneId: plBlobZone.id
        }
      }
    ]
  }
}

resource sacontent 'Microsoft.Storage/storageAccounts@2021-01-01' = {
  name: saContentUniqueName
  location: location
  tags: resourceTags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  identity:{
    type: 'SystemAssigned'
  }
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    isHnsEnabled: false
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'None'
    }
  }
}

resource sacontent_atp 'Microsoft.Security/advancedThreatProtectionSettings@2019-01-01' = {
  scope: sacontent
  name: 'current'
  properties: {
    isEnabled: true
  }
}

resource sacontent_privateLink 'Microsoft.Network/privateEndpoints@2020-08-01' = {
  name: '${saContentUniqueName}-private-link'
  location: location
  tags: resourceTags
  properties: {
    subnet: {
      id: vnet.properties.subnets[1].id
    }
    privateLinkServiceConnections: [
      {
        name: '${saContentUniqueName}-private-link'
        properties: {
          privateLinkServiceId: sacontent.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource sacontent_privateLink_zoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-08-01' = {
  name: '${sacontent_privateLink.name}/private-link'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: sacontent.name
        properties: {
          privateDnsZoneId: plBlobZone.id
        }
      }
    ]
  }
}

// ----- KEY VAULT

resource kv 'Microsoft.KeyVault/vaults@2020-04-01-preview' = {
  name: kvUniqueName
  location: location
  tags: resourceTags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: []
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enableRbacAuthorization: false
    createMode: 'default'
    enablePurgeProtection: true
    networkAcls: {
      bypass: 'None'
      defaultAction: 'Deny'
    }
  }
}

resource kv_accessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2020-04-01-preview' = {
  name: any('${kv.name}/add')
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: securityOwnerAADId
        //applicationId: null
        permissions: {
          keys: kvKeyPermissionsAll
          secrets: kvSecretsPermissionsAll
          certificates: kvCertificatesPermissionsAll
          storage: kvStoragePermissionsAll
        }
      }
    ]
  }
}

resource kv_diagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'DiagnosticSettings'
  scope: kv
  properties: {
    //storageAccountId:
    workspaceId: la.id
    // logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
    ]
  }
}

resource kv_privateLink 'Microsoft.Network/privateEndpoints@2020-08-01' = {
  name: '${kvUniqueName}-private-link'
  location: location
  tags: resourceTags
  properties: {
    subnet: {
      id: vnet.properties.subnets[1].id
    }
    privateLinkServiceConnections: [
      {
        name: '${kvUniqueName}-private-link'
        properties: {
          privateLinkServiceId: kv.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
  }
}

resource kv_privateLink_zoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-08-01' = {
  name: '${kv_privateLink.name}/private-link'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: kv.name
        properties: {
          privateDnsZoneId: plKVZone.id
        }
      }
    ]
  }
}

// ----- AZURE SQL DB

resource sql 'Microsoft.Sql/servers@2020-08-01-preview' = {
  name: sqlServerUniqueName
  location: location
  tags: resourceTags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administratorLogin: sqlServerLogin
    administratorLoginPassword: sqlServerPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
  }
}

resource sql_privateLink 'Microsoft.Network/privateEndpoints@2020-08-01' = {
  name: '${sqlServerUniqueName}-private-link'
  location: location
  tags: resourceTags
  properties: {
    subnet: {
      id: vnet.properties.subnets[1].id
    }
    privateLinkServiceConnections: [
      {
        name: '${sqlServerUniqueName}-private-link'
        properties: {
          privateLinkServiceId: sql.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
  }
}

resource sql_privateLink_zoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-08-01' = {
  name: '${sql_privateLink.name}/private-link'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: sql.name
        properties: {
          privateDnsZoneId: plSqlZone.id
        }
      }
    ]
  }
}

resource sql_AADAuth 'Microsoft.Sql/servers/administrators@2020-08-01-preview' = {
  name: '${sql.name}/activeDirectory'
  properties: {
    administratorType: 'ActiveDirectory'
    login: securityOwnerAADLogin
    sid: securityOwnerAADId
    tenantId: subscription().tenantId
  }
}

resource sql_auditingRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid('${lowerProjectPrefix}', resourceGroup().id, deployment().name, sql.name)
  scope: sadiag
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // Storage Blob Data Contributor
    principalId: reference(sql.id, '2019-06-01-preview', 'Full').identity.principalId
    principalType: 'ServicePrincipal'
    canDelegate: false
    description: 'SQL Auditing requires SQL Principal Id to have Blob Contributor role access to target storage account'
    //condition: 'string'
    //conditionVersion: '2.0'
  }
}

resource sql_devOpsAuditing 'Microsoft.Sql/servers/devOpsAuditingSettings@2020-08-01-preview' = {
  dependsOn: [
    sql_auditingRoleAssignment
  ]
  name: '${sql.name}/default'
  properties: {
    isAzureMonitorTargetEnabled: true
    state: 'Enabled'
    storageEndpoint: sadiag.properties.primaryEndpoints.blob
    //storageAccountAccessKey: null // not specifying the storageAccountAccessKey will use SQL server system-assigned managed identity to access the storage.
    storageAccountSubscriptionId: subscription().subscriptionId
  }
}

resource sql_securityAlertPolicies 'Microsoft.Sql/servers/securityAlertPolicies@2020-11-01-preview' = {
  dependsOn: [
    sql_devOpsAuditing
  ]
  name: '${sql.name}/default'
  properties: {
    state: 'Enabled'
    disabledAlerts: [
    ]
    emailAddresses: [
      securityAlertEmail
    ]
    emailAccountAdmins: securityEmailAdmins
    //storageEndpoint: sadiag.properties.primaryEndpoints.blob
    //storageAccountAccessKey: listKeys(sadiag.id, sadiag.apiVersion).keys[0].value
    retentionDays: logRetentionInDays
  }
}

resource sql_vulnerabilityAssessments 'Microsoft.Sql/servers/vulnerabilityAssessments@2020-08-01-preview' = {
  dependsOn: [
    sql_securityAlertPolicies
  ]
  name: '${sql.name}/default'
  properties: {
    storageContainerPath: '${sadiag.properties.primaryEndpoints.blob}vulnerability-assessment'
    //storageContainerSasKey: 'string'
    //storageAccountAccessKey: listKeys(sadiag.id, sadiag.apiVersion).keys[0].value
    recurringScans: {
      isEnabled: true
      emailSubscriptionAdmins: securityEmailAdmins
      emails: [
        securityAlertEmail
      ]
    }
  }
}

resource sql_auditingSettings 'Microsoft.Sql/servers/auditingSettings@2020-08-01-preview' = {
  dependsOn: [
    sql_devOpsAuditing
  ]
  name: '${sql.name}/default'
  properties: {
    isDevopsAuditEnabled: true
    retentionDays: logRetentionInDays
    auditActionsAndGroups: [
      'SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP'
      'FAILED_DATABASE_AUTHENTICATION_GROUP'
      'BATCH_COMPLETED_GROUP'
    ]
    isStorageSecondaryKeyInUse: false
    isAzureMonitorTargetEnabled: true
    //queueDelayMs: int
    state: 'Enabled'
    storageEndpoint: sadiag.properties.primaryEndpoints.blob
    //storageAccountAccessKey: null
    storageAccountSubscriptionId: subscription().subscriptionId
  }
}

resource sql_auditingSettingsEx 'Microsoft.Sql/servers/extendedAuditingSettings@2020-08-01-preview' = {
  dependsOn: [
    sql_auditingSettings
  ]
  name: '${sql.name}/default'
  properties: {
    isDevopsAuditEnabled: true
    //predicateExpression: 'string'
    retentionDays: logRetentionInDays
    auditActionsAndGroups: [
      'SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP'
      'FAILED_DATABASE_AUTHENTICATION_GROUP'
      'BATCH_COMPLETED_GROUP'
    ]
    isStorageSecondaryKeyInUse: false
    isAzureMonitorTargetEnabled: true
    //queueDelayMs: int
    state: 'Enabled'
    storageEndpoint: sadiag.properties.primaryEndpoints.blob
    //storageAccountAccessKey: null
    storageAccountSubscriptionId: subscription().subscriptionId
  }
}

resource sql_diagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'DiagnosticSettings'
  scope: sql
  properties: {
    //storageAccountId:
    workspaceId: la.id
    // logAnalyticsDestinationType: 'Dedicated'
    logs: [
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
    ]
  }
}

resource sqldb 'Microsoft.Sql/servers/databases@2020-08-01-preview' = {
  name: '${sql.name}/${sqlServerDBUniqueName}'
  location: location
  tags: resourceTags
  sku: {
    name: sqlServerDBSkuName
    tier: sqlServerDBTierName
  }
  properties: {
    createMode: 'Default'
    //collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 268435456000
    zoneRedundant: false
    licenseType: 'BasePrice'
    storageAccountType: 'ZRS'
  }
}

resource sqldb_diagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'DiagnosticSettings'
  scope: sqldb
  properties: {
    //storageAccountId:
    workspaceId: la.id
    // logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        category: 'SQLInsights'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
      {
        category: 'AutomaticTuning'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
      {
        category: 'QueryStoreRuntimeStatistics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
      {
        category: 'QueryStoreWaitStatistics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
      {
        category: 'Errors'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
      {
        category: 'DatabaseWaitStatistics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
      {
        category: 'Timeouts'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
      {
        category: 'Blocks'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
      {
        category: 'Deadlocks'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
    ]
    metrics: [
      {
        category: 'Basic'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
      {
        category: 'InstanceAndAppAdvanced'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
      {
        category: 'WorkloadManagement'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
    ]
  }
}

resource sqldb_strpBackup 'Microsoft.Sql/servers/databases/backupShortTermRetentionPolicies@2020-08-01-preview' = {
  name: '${sqldb.name}/Default'
  properties: {
    retentionDays: sqlServerDBTierName == 'Premium' ? 35 : sqlServerDBTierName == 'Standard' ? 35 : 7
  }
}

resource sqldb_ltrpBackup 'Microsoft.Sql/servers/databases/backupLongTermRetentionPolicies@2020-08-01-preview' = {
  name: '${sqldb.name}/Default'
  properties: {
    weeklyRetention: sqlServerDBWeeklyRetention
    monthlyRetention: sqlServerDBMonthlyRetention
    yearlyRetention: sqlServerDBYearlyRetention
    weekOfYear: sqlServerDBWeekOfYear
  }
}

// ----- AZURE App Service

// Linux currently NOT supported
resource appService_plan 'Microsoft.Web/serverfarms@2021-01-01' = {
  name: appSvcPlanUniqueName
  location: location
  tags: resourceTags
  properties: {
    perSiteScaling: false
    hyperV: false
  }
  sku: {
    name: appSvcPlanSkuName
  }
}

resource appService_planDiagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'DiagnosticSettings'
  scope: appService_plan
  properties: {
    //storageAccountId:
    workspaceId: la.id
    // logAnalyticsDestinationType: 'Dedicated'
    logs: [
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
    ]
  }
}

// ----- AZURE App Insights

resource appService_insights 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: appSvcInsightsUniqueName
  location: location
  tags: resourceTags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    Request_Source: 'rest'
    DisableIpMasking: false
    //ImmediatePurgeDataOn30Days: false
    WorkspaceResourceId: la.id
    publicNetworkAccessForIngestion: 'Enabled' // AppFunction can ingest over public EP
    publicNetworkAccessForQuery: 'Disabled'
    //IngestionMode: 'ApplicationInsightsWithDiagnosticSettings'
  }
}

resource appService_insightsDiagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'DiagnosticSettings'
  scope: appService_insights
  properties: {
    //storageAccountId:
    workspaceId: la.id
    // logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        category: 'AppAvailabilityResults'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
      {
        category: 'AppBrowserTimings'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
      {
        category: 'AppEvents'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
      {
        category: 'AppMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
      {
        category: 'AppDependencies'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
      {
        category: 'AppExceptions'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
      {
        category: 'AppPageViews'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
      {
        category: 'AppPerformanceCounters'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
      {
        category: 'AppRequests'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
      {
        category: 'AppSystemEvents'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
      {
        category: 'AppTraces'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
    ]
  }
}

// ----- AZURE Function App

resource appService_functionApp 'Microsoft.Web/sites@2021-01-01' = {
  name: appSvcFunctionUniqueName
  kind: 'functionapp'
  location: location
  tags: resourceTags
  properties: {
    enabled: true
    serverFarmId: appSvcPlanUniqueName
    siteConfig: {
      requestTracingEnabled: true
      remoteDebuggingEnabled: false
      httpLoggingEnabled: true
      //logsDirectorySizeLimit: int
      detailedErrorLoggingEnabled: true
      //publishingUsername: 'string'
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'WEBSITE_VNET_ROUTE_ALL'
          value: '1'
        }
        {
          name: 'WEBSITE_DNS_SERVER'
          value: '168.63.129.16'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference(appService_insights.id, '2014-04-01').InstrumentationKey
        }
      ]
      //azureStorageAccounts: {}
      connectionStrings: [
        {
          name: 'Default'
          connectionString: 'Server=tcp:${sqlServerUniqueName}.database.windows.net,1433;Initial Catalog=${sqlServerDBUniqueName};Authentication=Active Directory Integrated;Encrypt=True;'
          type: 'SQLAzure'
        }
      ]
      alwaysOn: true
      //tracingOptions: 'string'
      http20Enabled: true
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      ftpsState: 'Disabled'
      preWarmedInstanceCount: 1
    }
    httpsOnly: true
    storageAccountRequired: false
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource appService_functionAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'DiagnosticSettings'
  scope: appService_functionApp
  properties: {
    //storageAccountId:
    workspaceId: la.id
    // logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        category: 'FunctionAppLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: logRetentionInDays
        }
      }
    ]
  }
}

resource appService_functionAppNet 'Microsoft.Web/sites/networkConfig@2021-01-01' = {
  dependsOn:[
    appService_functionApp
  ]
  name: '${appSvcFunctionUniqueName}/VirtualNetwork'
  properties:{
    swiftSupported:true
    subnetResourceId:vnet.properties.subnets[0].id
  }
}
