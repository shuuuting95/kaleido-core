import { utils } from 'ethers'
import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'

const deploy: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deployer } = await getNamedAccounts()
  const { deploy } = deployments
  const NameRegistry = await deployments.get('NameRegistry')

  const Vault = await deploy('Vault', {
    from: deployer,
    args: [],
    log: true,
    deterministicDeployment: false,
  })

  const NameRegistryFactory = await hre.ethers.getContractFactory(
    'NameRegistry'
  )
  const name = NameRegistryFactory.attach(NameRegistry.address)
  const txReceipt = await name.set(
    utils.solidityKeccak256(['string'], ['Vault']),
    Vault.address,
    { gasLimit: 4500000 }
  )
  await txReceipt.wait()
  console.log(
    'Vault: ',
    await name.get(utils.solidityKeccak256(['string'], ['Vault']))
  )
}

export default deploy
