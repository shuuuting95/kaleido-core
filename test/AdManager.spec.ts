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

  const managerInstance = async (
    factory: ethers.Contract,
    name: ethers.Contract
  ) => {
    const { proxy } = await newMediaWith(factory, name)
    return _manager(proxy)
  }

  describe('newSpace', async () => {
    it('should new an ad space', async () => {
      const { factory, name } = await setupTests()
      const manager = await managerInstance(factory, name)
      const metadata = 'asfafkjksjfkajf'

      expect(await manager.newSpace(metadata))
        .to.emit(manager, 'NewSpace')
        .withArgs(metadata)
    })
  })

  describe('newPeirod', async () => {
    it('should new an ad period', async () => {
      const { now, factory, name } = await setupTests()
      const manager = await managerInstance(factory, name)
      const metadata = 'asfafkjksjfkajf'
      const fromTimestamp = now + 3600
      const toTimestamp = now + 7200
      const pricing = 0
      const minPrice = parseEther('0.2')
      const tokenId = await manager.adId(metadata, fromTimestamp, toTimestamp)

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
        .withArgs(
          tokenId,
          metadata,
          fromTimestamp,
          toTimestamp,
          pricing,
          minPrice
        )
    })
  })

  describe('buy', async () => {
    it('should buy a period', async () => {
      const { now, factory, name } = await setupTests()
      const manager = await managerInstance(factory, name)
      const metadata = 'asfafkjksjfkajf'
      const fromTimestamp = now + 3600
      const toTimestamp = now + 7200
      const tokenId = await manager.adId(metadata, fromTimestamp, toTimestamp)
      const pricing = 0
      const price = parseEther('0.2')
      await newPeriodWith(manager, {
        metadata: metadata,
        fromTimestamp: fromTimestamp,
        toTimestamp: toTimestamp,
        pricing: pricing,
        minPrice: price,
      })

      expect(
        await buyWith(manager.connect(user2), {
          tokenId,
          value: price,
        })
      )
        .to.emit(manager, 'Buy')
        .withArgs(tokenId, price, user2.address, now + 3)
    })
  })

  describe('withdraw', async () => {
    it('should buy a period', async () => {
      const { now, factory, name } = await setupTests()
      const manager = await managerInstance(factory, name)
      const metadata = 'asfafkjksjfkajf'
      const fromTimestamp = now + 3600
      const toTimestamp = now + 7200
      const tokenId = await manager.adId(metadata, fromTimestamp, toTimestamp)
      const pricing = 0
      const price = parseEther('0.2')
      await newPeriodWith(manager, {
        metadata: metadata,
        fromTimestamp: fromTimestamp,
        toTimestamp: toTimestamp,
        pricing: pricing,
        minPrice: price,
      })
      await buyWith(manager.connect(user2), {
        tokenId,
        value: price,
      })
      expect(await manager.withdraw())
        .to.emit(manager, 'Withdraw')
        .withArgs(parseEther('0.18'))
    })
  })

  describe('propose', async () => {
    it('should propose to the right you bought', async () => {
      const { now, factory, name } = await setupTests()
      const manager = await managerInstance(factory, name)
      const spaceMetadata = 'asfafkjksjfkajf'
      const fromTimestamp = now + 3600
      const toTimestamp = now + 7200
      const tokenId = await manager.adId(
        spaceMetadata,
        fromTimestamp,
        toTimestamp
      )
      const pricing = 0
      const price = parseEther('0.2')
      const proposalMetadata = 'asfdjakjajk3rq35jqwejrqk'
      await newPeriodWith(manager, {
        metadata: spaceMetadata,
        fromTimestamp: fromTimestamp,
        toTimestamp: toTimestamp,
        pricing: pricing,
        minPrice: price,
      })
      await buyWith(manager.connect(user2), {
        tokenId,
        value: price,
      })

      expect(await manager.connect(user2).propose(tokenId, proposalMetadata))
        .to.emit(manager, 'Propose')
        .withArgs(tokenId, proposalMetadata)
    })
  })

  describe('accept', async () => {
    it('should accept a proposal', async () => {
      const { now, factory, name } = await setupTests()
      const manager = await managerInstance(factory, name)
      const spaceMetadata = 'asfafkjksjfkajf'
      const fromTimestamp = now + 3600
      const toTimestamp = now + 7200
      const tokenId = await manager.adId(
        spaceMetadata,
        fromTimestamp,
        toTimestamp
      )
      const proposalMetadata = 'asfdjakjajk3rq35jqwejrqk'
      await newPeriodWith(manager, {
        metadata: spaceMetadata,
        fromTimestamp: fromTimestamp,
        toTimestamp: toTimestamp,
      })
      await buyWith(manager.connect(user2), {
        tokenId,
      })
      await manager.connect(user2).propose(tokenId, proposalMetadata)

      expect(await manager.accept(tokenId))
        .to.emit(manager, 'Accept')
        .withArgs(tokenId)
    })
  })
})

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

export type BuyProps = {
  tokenId: string
  value?: BigNumber
}

export const buyWith = async (manager: ethers.Contract, props: BuyProps) => {
  return await manager.buy(
    props.tokenId,
    option({ value: props.value ? props.value : parseEther('0.1') })
  )
}
