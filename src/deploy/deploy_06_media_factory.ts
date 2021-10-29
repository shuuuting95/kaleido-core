import { utils } from 'ethers'
import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { findNameRegistry } from '../common/nameRegistry'

const deploy: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deployer } = await getNamedAccounts()
  const { deploy } = deployments

  const name = await findNameRegistry(hre)

  const MediaFactory = await deploy('MediaFactory', {
    from: deployer,
    args: [name.address],
    log: true,
    deterministicDeployment: false,
  })

  const MediaFactoryKey = utils.solidityKeccak256(['string'], ['MediaFactory'])
  const MediaFactoryAddress = await name.get(MediaFactoryKey)
  if (MediaFactoryAddress !== MediaFactory.address) {
    const txReceipt = await name.set(MediaFactoryKey, MediaFactory.address, {
      gasLimit: 4500000,
    })
    await txReceipt.wait()
    console.log('MediaFactory: ', await name.get(MediaFactoryKey))
  }
}

export default deploy
