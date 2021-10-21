import { Contract } from 'ethers'
import { HardhatRuntimeEnvironment } from 'hardhat/types'

export const findNameRegistry = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, getNamedAccounts } = hre
  const NameRegistry = await deployments.get('NameRegistry')
  const NameRegistryFactory = await hre.ethers.getContractFactory(
    'NameRegistry'
  )
  const name: Contract = NameRegistryFactory.attach(NameRegistry.address)
  return name
}
