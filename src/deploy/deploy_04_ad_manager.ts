import { utils } from 'ethers'
import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'

const deploy: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deployer } = await getNamedAccounts()
  const { deploy } = deployments
  const NameRegistry = await deployments.get('NameRegistry')
  const IDGenerator = await deployments.get('IDGenerator')

  const AdManager = await deploy('AdManager', {
    from: deployer,
    args: [NameRegistry.address],
    log: true,
    deterministicDeployment: false,
    libraries: {
      IDGenerator: IDGenerator.address,
    },
  })

  const NameRegistryFactory = await hre.ethers.getContractFactory(
    'NameRegistry'
  )
  const name = NameRegistryFactory.attach(NameRegistry.address)
  const txReceipt = await name.set(
    utils.solidityKeccak256(['string'], ['AdManager']),
    AdManager.address,
    { gasLimit: 4500000 }
  )
  await txReceipt.wait()
  console.log(
    'AdManager: ',
    await name.get(utils.solidityKeccak256(['string'], ['AdManager']))
  )
}

export default deploy
