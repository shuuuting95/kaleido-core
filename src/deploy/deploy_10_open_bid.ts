import { utils } from 'ethers'
import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { findNameRegistry } from '../common/nameRegistry'

const deploy: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deployer } = await getNamedAccounts()
  const { deploy } = deployments
  const name = await findNameRegistry(hre)
  const target = hre.network.name === 'hardhat' ? 'MockTimeOpenBid' : 'OpenBid'

  const OpenBid = await deploy(target, {
    from: deployer,
    args: [name.address],
    log: true,
    deterministicDeployment: false,
  })

  const key = utils.solidityKeccak256(['string'], ['OpenBid'])
  const value = await name.get(key)
  if (value !== OpenBid.address) {
    const txReceipt = await name.set(key, OpenBid.address, {
      gasLimit: 4500000,
    })
    await txReceipt.wait()
    console.log('OpenBid: ', await name.get(key))
  }
}

export default deploy
