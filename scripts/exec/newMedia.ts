import { ethers } from 'ethers'
import { getMediaFactoryInstance } from '../common/contracts'
import {
  getAdManagerABI,
  getMediaFactoryAddress,
  getNameRegistryAddress,
} from '../common/file'
import { getWallet } from '../common/wallet'

const network = process.env.NETWORK || 'ganache'

const adminWallet = getWallet(0)

const main = async () => {
  const ifaceAdManager = new ethers.utils.Interface(getAdManagerABI())
  const initializer = ifaceAdManager.encodeFunctionData('initialize', [
    'Kaleido',
    'https://base/',
    getNameRegistryAddress(network),
  ])

  const factoryAddress = getMediaFactoryAddress(network)
  const mediaFactory = getMediaFactoryInstance(factoryAddress, adminWallet)

  const tx = await mediaFactory.newMedia(
    '_ojROEcQk1EJTEwYAovVBT0uh6t-X7YTDzHjxYLvCfY',
    initializer,
    1
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
