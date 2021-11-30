import { utils } from 'ethers'
import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { findNameRegistry } from '../common/nameRegistry'

const deploy: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deployer } = await getNamedAccounts()
  const { deploy } = deployments
  const name = await findNameRegistry(hre)

  {
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

  {
    const Sale = await deploy('Sale', {
      from: deployer,
      args: [],
      log: true,
      deterministicDeployment: false,
    })
    const key = utils.solidityKeccak256(['string'], ['Sale'])
    const value = await name.get(key)
    if (value !== Sale.address) {
      const txReceipt = await name.set(key, Sale.address, { gasLimit: 4500000 })
      await txReceipt.wait()
      console.log('Sale: ', await name.get(key))
    }
  }

  // {
  //   const Integers = await deploy('Integers', {
  //     from: deployer,
  //     args: [],
  //     log: true,
  //     deterministicDeployment: false,
  //   })
  //   const key = utils.solidityKeccak256(['string'], ['Integers'])
  //   const value = await name.get(key)
  //   if (value !== Integers.address) {
  //     const txReceipt = await name.set(key, Integers.address, {
  //       gasLimit: 4500000,
  //     })
  //     await txReceipt.wait()
  //     console.log('Integers: ', await name.get(key))
  //   }
  // }

  // {
  //   const Substrings = await deploy('Substrings', {
  //     from: deployer,
  //     args: [],
  //     log: true,
  //     deterministicDeployment: false,
  //   })
  //   const key = utils.solidityKeccak256(['string'], ['Substrings'])
  //   const value = await name.get(key)
  //   if (value !== Substrings.address) {
  //     const txReceipt = await name.set(key, Substrings.address, {
  //       gasLimit: 4500000,
  //     })
  //     await txReceipt.wait()
  //     console.log('Substrings: ', await name.get(key))
  //   }
  // }
}

export default deploy
