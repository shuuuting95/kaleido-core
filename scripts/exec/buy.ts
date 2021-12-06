import { parseEther } from '@ethersproject/units'
import { ethers } from 'ethers'
import { getMediaFacadeABI } from '../common/file'
import { getWallet } from '../common/wallet'
import { gasLimit } from './../common/wallet'

const network = process.env.NETWORK || 'ganache'

const adminWallet = getWallet(0)

const main = async () => {
  /////////////////////////////////
  // Param
  const proxy = '0x987d858343237f0CD1A791ad5F4bC5DB0ae1085A'
  const tokenId = 235237116874136
  /////////////////////////////////

  const manager = new ethers.Contract(proxy, getMediaFacadeABI(), adminWallet)

  const tx = await manager.buy(tokenId, {
    value: parseEther('0.1'),
    gasLimit: gasLimit(),
  })
  const rc = await tx.wait()
  const event = rc.events.find((event: any) => event.event === 'Buy')

  console.log('event: ', event)
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err)
    process.exit(1)
  })
