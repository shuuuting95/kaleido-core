import { ethers } from 'ethers'
import { create } from 'ipfs-http-client'
import fetch from 'node-fetch'
import { getMediaFactoryInstance } from '../common/contracts'
import {
  getMediaFacadeABI,
  getMediaFactoryAddress,
  getNameRegistryAddress,
} from '../common/file'
import { getWallet, option } from '../common/wallet'
import { NEW_MEDIA_TOKEN_INPUT } from '../inputs/newMediaInput'

const client = create({ url: 'https://ipfs.infura.io:5001' })

const network = process.env.NETWORK || 'ganache'
const MEDIA_EOA = process.env.MEDIA_EOA || ''
const MEDIA_METADATA_CID = process.env.MEDIA_METADATA_CID || ''

const adminWallet = getWallet(0)

const main = async () => {
  if (!MEDIA_EOA || !MEDIA_METADATA_CID)
    throw new Error('media eoa and metadata are required')
  const mediaMetadata = await fetch(
    `https://ipfs.infura.io/ipfs/${MEDIA_METADATA_CID}`
  ).then((res) => res.json())
  console.log('media metadata fetched:')
  console.log(JSON.stringify(mediaMetadata, null, 2))
  if (!mediaMetadata.name) throw new Error('invalid metadata')
  const metadata = await client.add(
    JSON.stringify({
      ...NEW_MEDIA_TOKEN_INPUT,
      name: mediaMetadata.name,
    })
  )
  console.log('token metadata uploaded:', metadata.path)
  const ifaceMediaFacade = new ethers.utils.Interface(getMediaFacadeABI())
  const initializer = ifaceMediaFacade.encodeFunctionData('initialize', [
    mediaMetadata.name,
    'ipfs://',
    metadata.path,
    MEDIA_EOA,
    getNameRegistryAddress(network),
  ])

  const factoryAddress = getMediaFactoryAddress(network)
  const mediaFactory = getMediaFactoryInstance(factoryAddress, adminWallet)

  const tx = await mediaFactory.newMedia(
    MEDIA_EOA,
    '',
    MEDIA_METADATA_CID,
    initializer,
    0,
    option()
  )
  const rc = await tx.wait()
  const event = rc.events.find((event: any) => event.event === 'CreateProxy')

  console.log('event: ', event)
  return event.args[0]
}

main()
  .then((res) => {
    console.log(res)
    process.exit(0)
  })
  .catch((err) => {
    console.error(err)
    process.exit(1)
  })
