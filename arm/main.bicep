
param location string = resourceGroup().location
param name string = 'minecraft'
param count int

var nsgName = 'nsg-${name}-${count}'

var worlds = [
  /*
  {
    name: 'Ahri'
    offset: 0
  }
  {
    name: 'Sky'
    offset: 20
  }
  */
  {
    name: 'Test'
    offset: 90
  }
]

resource nsg 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: nsgName
  location: location
}

resource nsgr 'Microsoft.Network/networkSecurityGroups/securityRules@2019-11-01' = [for (world, index) in worlds: {
  name: '${nsgName}/mc-${world.name}'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '${25565 + world.offset}'
    sourceAddressPrefix: '*'
    destinationAddressPrefix: '*'
    access: 'Allow'
    priority: 1000
    direction: 'Inbound'
  }
}]
