import { utils } from 'ethers'
import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { findNameRegistry } from '../common/nameRegistry'

const deploy: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deployer } = await getNamedAccounts()
  const { deploy } = deployments
  const name = await findNameRegistry(hre)

  const Ad = await deploy('Ad', {
    from: deployer,
    args: [],
    log: true,
    deterministicDeployment: false,
  })

  const key = utils.solidityKeccak256(['string'], ['Ad'])
  const value = await name.get(key)
  if (value !== Ad.address) {
    const txReceipt = await name.set(key, Ad.address, { gasLimit: 4500000 })
    await txReceipt.wait()
    console.log('Ad: ', await name.get(key))
  }
}

export default deploy
