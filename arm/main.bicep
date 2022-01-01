
param location string = resourceGroup().location
param name string = 'minecraft'
param count int
param vmSku string = 'Standard_B2s'
param adminUsername string
@secure()
param sshKey string

var vnetName = 'vnet-01'
var subnetName = 'default'


var nsgName = 'nsg-${name}-${count}'
var nicName = 'nic-${name}-${count}'
var vmName = 'vm-${name}-${count}'
var diskName = 'disk-${name}-${count}'


var worlds = [
  /*
  {
    name: 'ahri'
    offset: 0
  }
  {
    name: 'sky'
    offset: 20
  }
  */
  {
    name: 'test'
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

resource nic 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('rg-networking', 'Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

resource dataDisk 'Microsoft.Compute/disks@2021-04-01' = {
  name: diskName
  location: location
  sku: {
    name: 'StandardSSD_LRS'
  }
  properties: {
    creationData: {
      createOption: 'Empty'
    }
    diskSizeGB: 10
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSku
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          lun: 1
          createOption: 'Attach'
          managedDisk:{
            id: dataDisk.id
          }
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

output disk object = dataDisk
