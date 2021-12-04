import { ethers } from 'ethers'
import { getWallet } from '../common/wallet'

const network = process.env.NETWORK || 'ganache'

const adminWallet = getWallet(0)

const main = async () => {
  const hash = ethers.utils.solidityKeccak256(
    ['string', 'string'],
    ['sample', 'test']
  )
  const bin = ethers.utils.arrayify(hash)
  const sig = await adminWallet.signMessage(bin)
  console.log(sig)
  console.log(JSON.stringify({ test: 'test' }))
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err)
    process.exit(1)
  })
