import { utils } from 'ethers'
import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { findNameRegistry } from '../common/nameRegistry'

const deploy: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deployer } = await getNamedAccounts()
  const { deploy } = deployments
  const name = await findNameRegistry(hre)

  const AdManager = await deploy('AdManager', {
    from: deployer,
    args: [],
    log: true,
    deterministicDeployment: false,
  })

  const key = utils.solidityKeccak256(['string'], ['AdManager'])
  const value = await name.get(key)
  if (value !== AdManager.address) {
    const txReceipt = await name.set(key, AdManager.address, {
      gasLimit: 4500000,
    })
    await txReceipt.wait()
    console.log('AdManager: ', await name.get(key))
  }
}

export default deploy
