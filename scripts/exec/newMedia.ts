import { ethers } from 'ethers'
import { getMediaFactoryInstance } from '../common/contracts'
import {
  getAdManagerABI,
  getMediaFactoryAddress,
  getNameRegistryAddress,
} from '../common/file'
import { getWallet, option } from '../common/wallet'

const network = process.env.NETWORK || 'ganache'

const adminWallet = getWallet(0)

const main = async () => {
  const ifaceAdManager = new ethers.utils.Interface(getAdManagerABI())
  const initializer = ifaceAdManager.encodeFunctionData('initialize', [
    'Claime.io',
    'ipfs://',
    getNameRegistryAddress(network),
  ])

  const factoryAddress = getMediaFactoryAddress(network)
  const mediaFactory = getMediaFactoryInstance(factoryAddress, adminWallet)

  const tx = await mediaFactory.newMedia(
    '0xCdfc500F7f0FCe1278aECb0340b523cD55b3EBbb',
    '',
    'Qme81dBfEP94hH6UKPrkvnaHbKDK4dRek7bbT7a8aCF3Zr',
    initializer,
    0,
    option()
  )
  const rc = await tx.wait()
  const event = rc.events.find((event: any) => event.event === 'CreateProxy')

  console.log('event: ', event)
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err)
    process.exit(1)
  })
