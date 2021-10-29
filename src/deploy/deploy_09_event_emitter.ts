import { utils } from 'ethers'
import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { findNameRegistry } from '../common/nameRegistry'

const deploy: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deployer } = await getNamedAccounts()
  const { deploy } = deployments
  const name = await findNameRegistry(hre)
  const Ad = await deployments.get('Ad')

  const EventEmitter = await deploy('EventEmitter', {
    from: deployer,
    args: [name.address],
    log: true,
    deterministicDeployment: false,
    libraries: {
      Ad: Ad.address,
    },
  })

  const key = utils.solidityKeccak256(['string'], ['EventEmitter'])
  const value = await name.get(key)
  if (value !== EventEmitter.address) {
    const txReceipt = await name.set(key, EventEmitter.address, {
      gasLimit: 4500000,
    })
    await txReceipt.wait()
    console.log('EventEmitter: ', await name.get(key))
  }
}

export default deploy
