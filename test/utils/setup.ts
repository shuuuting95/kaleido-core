import hre, { deployments } from 'hardhat'

export const getAdManagerContract = async () => {
  const Deployment = await deployments.get('AdManager')
  const contract = await hre.ethers.getContractFactory('AdManager')
  return contract.attach(Deployment.address)
}

export const getDistributionRightContract = async () => {
  const Deployment = await deployments.get('DistributionRight')
  const contract = await hre.ethers.getContractFactory('DistributionRight')
  return contract.attach(Deployment.address)
}

export const getVaultContract = async () => {
  const Deployment = await deployments.get('Vault')
  const contract = await hre.ethers.getContractFactory('Vault')
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

export const getNameRegistryContract = async () => {
  const Deployment = await deployments.get('NameRegistry')
  const contract = await hre.ethers.getContractFactory('NameRegistry')
  return contract.attach(Deployment.address)
}
