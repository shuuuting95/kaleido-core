import IPFS from 'ipfs'

const main = async () => {
  const node = await IPFS.create()
  const data = 'Hello, KOIKE'
  const results = await node.add(data)
  console.log('result: ', results)

  const stream = node.cat(results.cid)
  let fetchedData = ''

  for await (const chunk of stream) {
    // chunks of data are returned as a Buffer, convert it back to a string
    fetchedData += chunk.toString()
  }
  console.log('fetcheddata: ', fetchedData)

  // for await (const { cid } of results) {
  //   // CID (Content IDentifier) uniquely addresses the data
  //   // and can be used to get it again.
  //   console.log(cid.toString())
  // }
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err)
    process.exit(1)
  })
