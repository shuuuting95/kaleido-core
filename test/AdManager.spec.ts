import { parseEther } from '@ethersproject/units'
import { expect } from 'chai'
import { BigNumber, ethers } from 'ethers'
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

  describe('newPeirod', async () => {
    it('should new an ad period', async () => {
      const { now, factory, name } = await setupTests()
      const { proxy } = await newMediaWith(factory, name)
      const manager = _manager(proxy)
      const metadata = 'asfafkjksjfkajf'
      const fromTimestamp = now + 3600
      const toTimestamp = now + 7200
      const pricing = 0
      const minPrice = parseEther('0.2')
      await newSpaceWith(manager, { metadata: metadata })

      expect(
        await newPeriodWith(manager, {
          metadata: metadata,
          fromTimestamp: fromTimestamp,
          toTimestamp: toTimestamp,
          pricing: pricing,
          minPrice: minPrice,
        })
      )
        .to.emit(manager, 'NewPeriod')
        .withArgs(metadata, fromTimestamp, toTimestamp, 0, pricing, minPrice)
    })
  })
})

export type NewSpaceProps = {
  metadata?: string
}

export const newSpaceWith = async (
  manager: ethers.Contract,
  props?: NewSpaceProps
) => {
  return await manager.newSpace(
    props?.metadata ? props.metadata : 'abi09nadu2brasfjl',
    option()
  )
}

export type NewPeriodProps = {
  metadata?: string
  fromTimestamp?: number
  toTimestamp?: number
  pricing?: number
  minPrice?: BigNumber
}

export const newPeriodWith = async (
  manager: ethers.Contract,
  props?: NewPeriodProps
) => {
  const now = Date.now()
  return await manager.newPeriod(
    props?.metadata ? props.metadata : 'abi09nadu2brasfjl',
    props?.fromTimestamp ? props.fromTimestamp : now + 3600,
    props?.toTimestamp ? props.toTimestamp : now + 7200,
    props?.pricing ? props.pricing : 0,
    props?.minPrice ? props.minPrice : parseEther('0.1'),
    option()
  )
}
