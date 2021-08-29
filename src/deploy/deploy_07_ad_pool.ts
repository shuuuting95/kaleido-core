import { utils } from 'ethers'
import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'

const deploy: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deployer } = await getNamedAccounts()
  const { deploy } = deployments
  const NameRegistry = await deployments.get('NameRegistry')

  const AdPool = await deploy('AdPool', {
    from: deployer,
    args: [NameRegistry.address],
    log: true,
    deterministicDeployment: false,
  })

  const NameRegistryFactory = await hre.ethers.getContractFactory(
    'NameRegistry'
  )
  const name = NameRegistryFactory.attach(NameRegistry.address)
  const key = utils.solidityKeccak256(['string'], ['AdPool'])
  const value = await name.get(key)
  if (value !== AdPool.address) {
    const txReceipt = await name.set(key, AdPool.address, { gasLimit: 4500000 })
    await txReceipt.wait()
    console.log('AdPool: ', await name.get(key))
  }
}

export default deploy
