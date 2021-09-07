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

export const getPostOwnerPoolContract = async () => {
  const Deployment = await deployments.get('PostOwnerPool')
  const contract = await hre.ethers.getContractFactory('PostOwnerPool')
  return contract.attach(Deployment.address)
}