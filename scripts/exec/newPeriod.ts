import { parseEther } from '@ethersproject/units'
import { ethers } from 'ethers'
import { getMediaFacadeABI } from '../common/file'
import { getWallet } from '../common/wallet'

const network = process.env.NETWORK || 'ganache'

const adminWallet = getWallet(0)

const main = async () => {
  /////////////////////////////////
  // Param
  const proxy = '0x987d858343237f0CD1A791ad5F4bC5DB0ae1085A'
  /////////////////////////////////

  const manager = new ethers.Contract(proxy, getMediaFacadeABI(), adminWallet)

  const now = Date.now()
  const tx = await manager.newPeriod(
    'abi09nadu2brasfjl',
    now + 13600,
    now + 17200,
    0,
    parseEther('0.1')
  )
  const rc = await tx.wait()
  const event = rc.events.find((event: any) => event.event === 'NewPeriod')

  console.log('event: ', event)
  console.log('tokenId: ', Number(event.args.tokenId))
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err)
    process.exit(1)
  })
