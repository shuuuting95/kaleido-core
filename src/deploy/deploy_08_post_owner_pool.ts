import { utils } from 'ethers'
import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'

const deploy: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deployer } = await getNamedAccounts()
  const { deploy } = deployments
  const NameRegistry = await deployments.get('NameRegistry')

  const PostOwnerPool = await deploy('PostOwnerPool', {
    from: deployer,
    args: [NameRegistry.address],
    log: true,
    deterministicDeployment: false,
  })

  const NameRegistryFactory = await hre.ethers.getContractFactory(
    'NameRegistry'
  )
  const name = NameRegistryFactory.attach(NameRegistry.address)
  const key = utils.solidityKeccak256(['string'], ['PostOwnerPool'])
  const value = await name.get(key)
  if (value !== PostOwnerPool.address) {
    const txReceipt = await name.set(key, PostOwnerPool.address, {
      gasLimit: 4500000,
    })
    await txReceipt.wait()
    console.log('PostOwnerPool: ', await name.get(key))
  }
}

export default deploy
