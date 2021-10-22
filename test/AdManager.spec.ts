import { expect } from 'chai'
import { ethers } from 'ethers'
import { deployments, network, waffle } from 'hardhat'
import { getAdManagerABI } from '../scripts/common/file'
import { option } from '../scripts/common/wallet'
import { newMediaWith } from './MediaFactory.spec'
import {
  getAdManagerContract,
  getMediaFactoryContract,
  getMediaRegistryContract,
  getNameRegistryContract,
} from './utils/setup'

describe('AdManager', async () => {
  const [user1, user2, user3] = waffle.provider.getWallets()

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
  const _manager = (proxy: string) =>
    new ethers.Contract(proxy, getAdManagerABI(), user1)

  describe('newSpace', async () => {
    it('should new an ad space', async () => {
      const { factory, name } = await setupTests()
      const { proxy } = await newMediaWith(factory, name)
      const manager = _manager(proxy)
      const metadata = 'asfafkjksjfkajf'

      expect(await newSpaceWith(manager, { metadata: metadata }))
        .to.emit(manager, 'NewSpace')
        .withArgs(metadata)
    })
  })
})

export type DonateProps = {
  metadata?: string
}

export const newSpaceWith = async (
  manager: ethers.Contract,
  props?: DonateProps
) => {
  return await manager.newSpace(
    props?.metadata ? props.metadata : 'abi09nadu2brasfjl',
    option()
  )
}
