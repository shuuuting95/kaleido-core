import { File, NFTStorage } from 'nft.storage'

const main = async () => {
  const apiKey = process.env.NFT_STORAGE || ''
  const client = new NFTStorage({ token: apiKey })
  const metadata = await client.store({
    name: 'Pinpie',
    description: 'Pin is not delicious beef!',
    image: new File(
      [
        /* data */
      ],
      'pinpie.jpg',
      { type: 'image/jpg' }
    ),
  })
  console.log(metadata.url)

  // const node = await IPFS.create()
  // const data = 'Hello, KOIKE'
  // const results = await node.add(data)
  // console.log('result: ', results)
  // const stream = node.cat(results.cid)
  // let fetchedData = ''
  // for await (const chunk of stream) {
  //   // chunks of data are returned as a Buffer, convert it back to a string
  //   fetchedData += chunk.toString()
  // }
  // console.log('fetcheddata: ', fetchedData)
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err)
    process.exit(1)
  })
