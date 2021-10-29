import { utils } from 'ethers'
import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { option } from '../../scripts/common/wallet'
import { findNameRegistry } from '../common/nameRegistry'

const deploy: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deployer } = await getNamedAccounts()
  const { deploy } = deployments
  const name = await findNameRegistry(hre)

  const AdPool = await deploy('AdPool', {
    from: deployer,
    args: [name.address],
    log: true,
    deterministicDeployment: false,
  })

  const key = utils.solidityKeccak256(['string'], ['AdPool'])
  const value = await name.get(key)
  if (value !== AdPool.address) {
    const txReceipt = await name.set(key, AdPool.address, option())
    await txReceipt.wait()
    console.log('AdPool: ', await name.get(key))
  }
}

export default deploy
