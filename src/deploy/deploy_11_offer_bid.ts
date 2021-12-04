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
  const Purchase = await deployments.get('Purchase')

  const OfferBid = await deploy('OfferBid', {
    from: deployer,
    args: [name.address],
    log: true,
    deterministicDeployment: false,
    libraries: {
      Ad: Ad.address,
      Purchase: Purchase.address,
    },
  })

  const key = utils.solidityKeccak256(['string'], ['OfferBid'])
  const value = await name.get(key)
  if (value !== OfferBid.address) {
    const txReceipt = await name.set(key, OfferBid.address, {
      gasLimit: 4500000,
    })
    await txReceipt.wait()
    console.log('OfferBid: ', await name.get(key))
  }
}

export default deploy
