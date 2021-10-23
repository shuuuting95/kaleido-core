import { utils } from 'ethers'
import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { findNameRegistry } from '../common/nameRegistry'

const deploy: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deployer } = await getNamedAccounts()
  const { deploy } = deployments
  const name = await findNameRegistry(hre)
  const Integers = await deployments.get('Integers')
  const Substrings = await deployments.get('Substrings')

  const Bundler = await deploy('Bundler', {
    from: deployer,
    args: [name.address],
    log: true,
    deterministicDeployment: false,
    libraries: {
      Integers: Integers.address,
      Substrings: Substrings.address,
    },
  })

  const key = utils.solidityKeccak256(['string'], ['Bundler'])
  const value = await name.get(key)
  if (value !== Bundler.address) {
    const txReceipt = await name.set(key, Bundler.address, {
      gasLimit: 4500000,
    })
    await txReceipt.wait()
    console.log('Bundler: ', await name.get(key))
  }
}

export default deploy
