import { getWallet, option } from '../common/wallet'
import { getAdManagerInstance } from './../common/contracts'

const network = process.env.NETWORK || 'ganache'

const adminWallet = getWallet(0)

const main = async () => {
  const proxyAddress = '0xf4b2527492bdb330925c84831a889c725a0eb191'
  const adManager = getAdManagerInstance(proxyAddress, adminWallet)

  const tx = await adManager.newSpace(
    'QmPUdYTNB3pCc47aepmTtkx5aNbSvc6QRAUMv6jSUBWTpC',
    option()
  )
  const rc = await tx.wait()
  console.log('rc: ', rc)
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err)
    process.exit(1)
  })
