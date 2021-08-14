import hre, { deployments } from 'hardhat'

export const getAdManagerContract = async () => {
  const Deployment = await deployments.get('AdManager')
  const IDGenerator = await deployments.get('IDGenerator')
  const contract = await hre.ethers.getContractFactory('AdManager', {
    libraries: {
      IDGenerator: IDGenerator.address,
    },
  })
  return contract.attach(Deployment.address)
}

export const getDistributionRightContract = async () => {
  const Deployment = await deployments.get('DistributionRight')
  const contract = await hre.ethers.getContractFactory('DistributionRight')
  return contract.attach(Deployment.address)
}