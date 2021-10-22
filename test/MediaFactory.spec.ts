import { expect } from 'chai'
import { BigNumber, ethers } from 'ethers'
import { deployments, network, waffle } from 'hardhat'
import { getAdManagerABI } from '../scripts/common/file'
import {
  getAdManagerContract,
  getMediaFactoryContract,
  getMediaRegistryContract,
  getNameRegistryContract,
} from './utils/setup'

describe('MediaFactory', async () => {
  const [user1, user2, user3, user4, user5] = waffle.provider.getWallets()

  const setupTests = deployments.createFixture(async ({ deployments }) => {
    await deployments.fixture()
    const now = Date.now()
    await network.provider.send('evm_setNextBlockTimestamp', [now])
    await network.provider.send('evm_mine')
    return {
      now: now,
      factory: await getMediaFactoryContract(),
      manager: await getAdManagerContract(),
      name: await getNameRegistryContract(),
      registry: await getMediaRegistryContract(),
    }
  })

  describe('newMedia', async () => {
    it('should new a account of media', async () => {
      const { now, factory, manager, name, registry } = await setupTests()

      const { proxy, singleton } = await newMediaWith(factory, name)
      expect(proxy).is.not.null
      expect(singleton).to.be.eq(name.address)
      expect(await registry.allAccounts(proxy)).to.be.eq(user1.address)
    })
  })
})

export type PostProps = {
  initializer?: string
  metadata?: string
  maxCount?: BigNumber
  maxAmount?: BigNumber
  saltNonce?: number
}

export const newMediaWith = async (
  factory: ethers.Contract,
  name: ethers.Contract,
  props?: PostProps
) => {
  const ifaceAdManager = new ethers.utils.Interface(getAdManagerABI())
  const initializer = ifaceAdManager.encodeFunctionData('init', [name.address])
  const tx = await factory.newMedia(
    props?.initializer ? props.initializer : initializer,
    props?.saltNonce ? props.saltNonce : 1
  )
  const rc = await tx.wait()
  const event = rc.events.find((event: any) => event.event === 'CreateProxy')
  return event.args
}
