import hre, { deployments } from 'hardhat'

export const getAdManagerContract = async () => {
  const Deployment = await deployments.get('MockTimeAdManager')
  const contract = await hre.ethers.getContractFactory('MockTimeAdManager', {
    libraries: {
      Ad: (await deployments.get('Ad')).address,
    },
  })
  return contract.attach(Deployment.address)
}

export const getBundlerContract = async () => {
  const Deployment = await deployments.get('Bundler')
  const contract = await hre.ethers.getContractFactory('Bundler', {
    libraries: {
      Integers: (await deployments.get('Integers')).address,
      Substrings: (await deployments.get('Substrings')).address,
    },
  })
  return contract.attach(Deployment.address)
}

export const getVaultContract = async () => {
  const Deployment = await deployments.get('Vault')
  const contract = await hre.ethers.getContractFactory('Vault')
  return contract.attach(Deployment.address)
}

export const getEventEmitterContract = async () => {
  const Deployment = await deployments.get('EventEmitter')
  const contract = await hre.ethers.getContractFactory('EventEmitter')
  return contract.attach(Deployment.address)
}

export const getMediaFactoryContract = async () => {
  const Deployment = await deployments.get('MediaFactory')
  const contract = await hre.ethers.getContractFactory('MediaFactory')
  return contract.attach(Deployment.address)
}

export const getMediaRegistryContract = async () => {
  const Deployment = await deployments.get('MediaRegistry')
  const contract = await hre.ethers.getContractFactory('MediaRegistry')
  return contract.attach(Deployment.address)
}

export const getAdPoolContract = async () => {
  const Deployment = await deployments.get('AdPool')
  const contract = await hre.ethers.getContractFactory('AdPool')
  return contract.attach(Deployment.address)
}

export const getNameRegistryContract = async () => {
  const Deployment = await deployments.get('NameRegistry')
  const contract = await hre.ethers.getContractFactory('NameRegistry')
  return contract.attach(Deployment.address)
}
