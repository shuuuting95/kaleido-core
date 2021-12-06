import { utils } from 'ethers'
import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { findNameRegistry } from '../common/nameRegistry'
import { option } from './../../scripts/common/wallet'

const deploy: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deployer } = await getNamedAccounts()
  const { deploy } = deployments
  const name = await findNameRegistry(hre)
  const Ad = await deployments.get('Ad')
  const Schedule = await deployments.get('Schedule')
  const Sale = await deployments.get('Sale')
  const Purchase = await deployments.get('Purchase')

  const target = hre.network.name === 'hardhat' ? 'MockTimeAdPool' : 'AdPool'

  const AdPool = await deploy(target, {
    from: deployer,
    args: [name.address],
    log: true,
    deterministicDeployment: false,
    libraries: {
      Ad: Ad.address,
      Schedule: Schedule.address,
      Sale: Sale.address,
      Purchase: Purchase.address,
    },
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
