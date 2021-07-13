param location string
param tags object
param storageId string
param workspaceId string
param workspaceRegion string
param workspaceResourceId string
param retentionInDays int
param nsgAppServiceId string
param nsgAppServiceName string
param nsgPrivateLinkId string
param nsgPrivateLinkName string

resource nsgDataPlane_flowLogs 'Microsoft.Network/networkWatchers/flowLogs@2020-08-01' = {
  name: 'NetworkWatcher_${location}/${nsgAppServiceName}'
  location: location
  tags: tags
  properties: {
    targetResourceId: nsgAppServiceId
    storageId: storageId
    enabled: true
    retentionPolicy: {
      days: retentionInDays
      enabled: true
    }
    format: {
      type: 'JSON'
      version: 2
    }
    flowAnalyticsConfiguration: {
      networkWatcherFlowAnalyticsConfiguration: {
        enabled: true
        workspaceId: workspaceId
        workspaceRegion: workspaceRegion
        workspaceResourceId: workspaceResourceId
        //trafficAnalyticsInterval: int
      }
    }
  }
}

resource nsgPrivateLink_flowLogs 'Microsoft.Network/networkWatchers/flowLogs@2020-08-01' = {
  name: 'NetworkWatcher_${location}/${nsgPrivateLinkName}'
  location: location
  tags: tags
  properties: {
    targetResourceId: nsgPrivateLinkId
    storageId: storageId
    enabled: true
    retentionPolicy: {
      days: retentionInDays
      enabled: true
    }
    format: {
      type: 'JSON'
      version: 2
    }
    flowAnalyticsConfiguration: {
      networkWatcherFlowAnalyticsConfiguration: {
        enabled: true
        workspaceId: workspaceId
        workspaceRegion: workspaceRegion
        workspaceResourceId: workspaceResourceId
        //trafficAnalyticsInterval: int
      }
    }
  }
}
