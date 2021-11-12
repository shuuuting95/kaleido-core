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
    'Kaleido',
    'ipfs://jkasjkfajkjakjskjfa;k/',
    getNameRegistryAddress(network),
  ])

  const factoryAddress = getMediaFactoryAddress(network)
  const mediaFactory = getMediaFactoryInstance(factoryAddress, adminWallet)

  const tx = await mediaFactory.newMedia(
    '0xf19fb9fe1725bc6e3615e5ad656d3b8fc3b12176',
    '_ojROEcQk1EJTEwYAovVBT0uh6t-X7YTDzHjxYLvCfY',
    initializer,
    3,
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
