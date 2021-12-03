import { parseEther } from '@ethersproject/units'
import { expect } from 'chai'
import { BigNumber, ethers } from 'ethers'
import { deployments, network, waffle } from 'hardhat'
import {
  getAdManagerABI,
  getMockTimeAdManagerABI,
} from '../scripts/common/file'
import { option } from '../scripts/common/wallet'
import { newMediaWith } from './MediaFactory.spec'
import { ADDRESS_ZERO } from './utils/address'
import {
  getAdPoolContract,
  getEventEmitterContract,
  getMediaFactoryContract,
  getMediaRegistryContract,
  getNameRegistryContract,
} from './utils/setup'

describe('AdManager', async () => {
  // user1: Deployer (Bridges)
  // user2: Media
  // user3: Buyer, Ad Owner
  // user4: Wrong others
  // user5: Another Media
  const [user1, user2, user3, user4, user5] = waffle.provider.getWallets()

  const setupTests = deployments.createFixture(async ({ deployments }) => {
    await deployments.fixture()
    const now = Date.now()
    await network.provider.send('evm_setNextBlockTimestamp', [now])
    await network.provider.send('evm_mine')

    return {
      now: now,
      factory: await getMediaFactoryContract(),
      name: await getNameRegistryContract(),
      registry: await getMediaRegistryContract(),
      pool: await getAdPoolContract(),
      event: await getEventEmitterContract(),
    }
  })
  const _manager = (proxy: string) =>
    new ethers.Contract(proxy, getMockTimeAdManagerABI(), user2)

  const managerInstance = async (
    factory: ethers.Contract,
    name: ethers.Contract,
    now: number
  ) => {
    const { proxy } = await newMediaWith(user2, factory, name)
    const manager = _manager(proxy)
    await manager.setTime(now)
    return manager
  }

  describe('initialize', async () => {
    it('should initialize', async () => {
      const { now, factory, registry, name, event } = await setupTests()
      const manager = await managerInstance(factory, name, now)

      expect(await manager.name()).to.be.eq('BridgesMedia')
      expect(await manager.symbol()).to.be.eq('Kaleido_BridgesMedia')
      expect(await manager.nameRegistryAddress()).to.be.eq(name.address)
    })
  })

  describe('updateMedia', async () => {
    it('should update a media', async () => {
      const { now, factory, registry, name, event } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const newMetadata = 'sfjjrtjwjtkljwlejr;tfjk'

      expect(
        await manager.connect(user2).updateMedia(user4.address, newMetadata)
      )
        .to.emit(event, 'UpdateMedia')
        .withArgs(manager.address, user4.address, newMetadata)
    })

    it('should revert because the sender is not the media EOA', async () => {
      const { now, factory, registry, name, event } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const newMetadata = 'sfjjrtjwjtkljwlejr;tfjk'

      await expect(
        manager.connect(user4).updateMedia(user4.address, newMetadata)
      ).to.be.revertedWith('KD012')
    })
  })

  describe('newSpace', async () => {
    it('should new an ad space', async () => {
      const { now, factory, name, event } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const spaceMetadata = 'asfafkjksjfkajf'

      expect(await manager.newSpace(spaceMetadata))
        .to.emit(event, 'NewSpace')
        .withArgs(spaceMetadata)
      expect(await manager.spaced(spaceMetadata)).to.be.true
    })

    it('should revert because the space has already created', async () => {
      const { now, factory, name } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const spaceMetadata = 'asfafkjksjfkajf'
      await manager.newSpace(spaceMetadata)

      await expect(manager.newSpace(spaceMetadata)).to.be.revertedWith('KD100')
    })

    it('should revert because the space has already created by another media', async () => {
      const { now, factory, name } = await setupTests()
      const manager2 = await managerInstance(factory, name, now)
      const { proxy } = await newMediaWith(user5, factory, name, {
        saltNonce: 100,
      })
      const manager5 = new ethers.Contract(proxy, getAdManagerABI(), user5)
      const spaceMetadata = 'asfafkjksjfkajf'
      await manager5.newSpace(spaceMetadata)

      await expect(manager2.newSpace(spaceMetadata)).to.be.revertedWith('KD100')
    })
  })

  describe('newPeirod', async () => {
    it('should new an ad period', async () => {
      const { now, factory, name, event, pool } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const spaceMetadata = 'asfafkjksjfkajf'
      const tokenMetadata = 'poiknfknajnjaer'
      const saleEndTimestamp = now + 2400
      const displayStartTimestamp = now + 3600
      const displayEndTimestamp = now + 7200
      const pricing = 0
      const minPrice = parseEther('0.2')
      const tokenId = await manager.adId(
        spaceMetadata,
        displayStartTimestamp,
        displayEndTimestamp
      )

      expect(
        await newPeriodWith(manager, {
          spaceMetadata: spaceMetadata,
          tokenMetadata: tokenMetadata,
          saleEndTimestamp: saleEndTimestamp,
          displayStartTimestamp: displayStartTimestamp,
          displayEndTimestamp: displayEndTimestamp,
          pricing: pricing,
          minPrice: minPrice,
        })
      )
        .to.emit(event, 'NewPeriod')
        .withArgs(
          tokenId,
          spaceMetadata,
          tokenMetadata,
          now,
          saleEndTimestamp,
          displayStartTimestamp,
          displayEndTimestamp,
          pricing,
          minPrice
        )
        .to.emit(event, 'TransferCustom')
        .withArgs(ADDRESS_ZERO, manager.address, tokenId)
      expect(await manager.spaced(spaceMetadata)).to.be.true
      expect(await manager.tokenIdsOf(spaceMetadata)).to.deep.equal([tokenId])
      expect(await manager.periods(tokenId)).to.deep.equal([
        manager.address,
        spaceMetadata,
        tokenMetadata,
        BigNumber.from(now),
        BigNumber.from(saleEndTimestamp),
        BigNumber.from(displayStartTimestamp),
        BigNumber.from(displayEndTimestamp),
        pricing,
        minPrice,
        minPrice,
        false,
      ])
      expect(await manager.ownerOf(tokenId)).to.be.eq(manager.address)
      expect(await manager.tokenURI(tokenId)).to.be.eq(
        `ipfs://${tokenMetadata}`
      )
      expect(await pool.allPeriods(tokenId)).to.deep.equal([
        manager.address,
        spaceMetadata,
        tokenMetadata,
        BigNumber.from(now),
        BigNumber.from(saleEndTimestamp),
        BigNumber.from(displayStartTimestamp),
        BigNumber.from(displayEndTimestamp),
        pricing,
        minPrice,
        minPrice,
        false,
      ])
    })

    it('should revert because the media is not yours', async () => {
      const { now, factory, name } = await setupTests()
      const manager = await managerInstance(factory, name, now)

      await expect(newPeriodWith(manager.connect(user4))).to.be.revertedWith(
        'KD012'
      )
    })

    it('should revert because of overlapped period', async () => {
      const { now, factory, name } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const saleEndTimestamp = now + 2400
      const displayStartTimestamp = now + 3600
      const displayEndTimestamp = now + 7200

      await newPeriodWith(manager, {
        saleEndTimestamp: saleEndTimestamp,
        displayStartTimestamp: displayStartTimestamp,
        displayEndTimestamp: displayEndTimestamp,
      })
      await expect(
        newPeriodWith(manager, {
          saleEndTimestamp: now + 5000,
          displayStartTimestamp: now + 7100,
          displayEndTimestamp: now + 9000,
        })
      ).to.be.revertedWith('KD110')
    })

    it('should revert because the sale end time is the past', async () => {
      const { now, factory, name } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const saleEndTimestamp = now - 1000

      await expect(
        newPeriodWith(manager, {
          saleEndTimestamp: saleEndTimestamp,
        })
      ).to.be.revertedWith('KD111')
    })

    it('should revert because the display start time is before the end of the sale', async () => {
      const { now, factory, name } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const saleEndTimestamp = now + 3600
      const displayStartTimestamp = now + 2400
      const displayEndTimestamp = now + 7200

      await expect(
        newPeriodWith(manager, {
          saleEndTimestamp: saleEndTimestamp,
          displayStartTimestamp: displayStartTimestamp,
          displayEndTimestamp: displayEndTimestamp,
        })
      ).to.be.revertedWith('KD112')
    })

    it('should revert because the display end time is before the start of the display', async () => {
      const { now, factory, name } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const displayStartTimestamp = now + 7200
      const displayEndTimestamp = now + 3600

      await expect(
        newPeriodWith(manager, {
          displayStartTimestamp: displayStartTimestamp,
          displayEndTimestamp: displayEndTimestamp,
        })
      ).to.be.revertedWith('KD113')
    })
  })

  describe('deletePeriod', async () => {
    it('should delete a period', async () => {
      const { now, factory, name, event, pool } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId } = await defaultPeriodProps(manager, now)
      await newPeriodWith(manager, { now })

      expect(await manager.deletePeriod(tokenId, option()))
        .to.emit(event, 'DeletePeriod')
        .withArgs(tokenId)
        .to.emit(event, 'TransferCustom')
        .withArgs(manager.address, ADDRESS_ZERO, tokenId)
      await expect(manager.ownerOf(tokenId)).to.be.revertedWith('KD114')
      expect(await pool.allPeriods(tokenId)).to.deep.equal([
        ADDRESS_ZERO,
        '',
        '',
        BigNumber.from(0),
        BigNumber.from(0),
        BigNumber.from(0),
        BigNumber.from(0),
        0,
        BigNumber.from(0),
        BigNumber.from(0),
        false,
      ])
    })

    it('should revert because it has already deleted', async () => {
      const { now, factory, name } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId } = await defaultPeriodProps(manager, now)

      await newPeriodWith(manager, { now })
      await manager.deletePeriod(tokenId, option())
      await expect(manager.deletePeriod(tokenId, option())).to.be.revertedWith(
        'KD114'
      )
    })

    it('should revert because it has been sold out', async () => {
      const { now, factory, name } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId } = await defaultPeriodProps(manager, now)

      await newPeriodWith(manager.connect(user2), { now })
      await buyWith(manager.connect(user3), {
        tokenId,
        value: parseEther('0.1'),
      })
      await expect(manager.deletePeriod(tokenId, option())).to.be.revertedWith(
        'KD121'
      )
    })

    it('should delete repeatedly', async () => {
      const { now, factory, name } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId, spaceMetadata } = await defaultPeriodProps(manager, now)

      await newPeriodWith(manager, { now })
      await manager.deletePeriod(tokenId, option())

      await newPeriodWith(manager, { now })
      await manager.deletePeriod(tokenId, option())

      await newPeriodWith(manager, { now })
      expect(await manager.tokenIdsOf(spaceMetadata)).to.deep.equal([
        BigNumber.from(0),
        BigNumber.from(0),
        tokenId,
      ])
    })

    it('should not delete because someone has already bid', async () => {
      const { now, factory, name, event, pool } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId } = await defaultPeriodProps(manager, now)
      await newPeriodWith(manager, { now, pricing: 2 })
      await manager
        .connect(user3)
        .bid(tokenId, option({ value: parseEther('0.3') }))

      await expect(manager.deletePeriod(tokenId, option())).to.be.revertedWith(
        'KD128'
      )
    })

    it('should not delete because someone has already bid with a proposal', async () => {
      const { now, factory, name, event, pool } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId } = await defaultPeriodProps(manager, now)
      const metadata = '3wijisdkfj;alkjda'
      await newPeriodWith(manager, { now, pricing: 4 })
      await manager
        .connect(user3)
        .bidWithProposal(
          tokenId,
          metadata,
          option({ value: parseEther('0.3') })
        )

      await expect(manager.deletePeriod(tokenId, option())).to.be.revertedWith(
        'KD128'
      )
    })
  })

  describe('offerPeriod', async () => {
    it('should offer', async () => {
      const { now, factory, name, event } = await setupTests()
      const manager = await managerInstance(factory, name, now)

      const spaceMetadata = 'asfafkjksjfkajf'
      const displayStartTimestamp = now + 3600
      const displayEndTimestamp = now + 7200
      const tokenId = await manager.adId(
        spaceMetadata,
        displayStartTimestamp,
        displayEndTimestamp
      )
      const price = parseEther('0.4')
      await manager.connect(user2).newSpace(spaceMetadata)
      expect(
        await manager
          .connect(user3)
          .offerPeriod(
            spaceMetadata,
            displayStartTimestamp,
            displayEndTimestamp,
            option({ value: price })
          )
      )
        .to.emit(event, 'OfferPeriod')
        .withArgs(
          tokenId,
          spaceMetadata,
          displayStartTimestamp,
          displayEndTimestamp,
          user3.address,
          price
        )
    })

    it('should revert because of missing the space', async () => {
      const { now, factory, name } = await setupTests()
      const manager = await managerInstance(factory, name, now)

      const wrongSpaceMetadata = 'asdfadfaweferhertheaeerwerafadfa'
      const displayStartTimestamp = now + 3600
      const displayEndTimestamp = now + 7200
      const price = parseEther('0.4')
      await expect(
        manager
          .connect(user3)
          .offerPeriod(
            wrongSpaceMetadata,
            displayStartTimestamp,
            displayEndTimestamp,
            option({ value: price })
          )
      ).to.be.revertedWith('KD101')
    })
  })

  describe('cancelOffer', async () => {
    it('should cancel an offer', async () => {
      const { now, factory, name, event } = await setupTests()
      const manager = await managerInstance(factory, name, now)

      const spaceMetadata = 'asfafkjksjfkajf'
      const displayStartTimestamp = now + 3600
      const displayEndTimestamp = now + 7200
      const tokenId = await manager.adId(
        spaceMetadata,
        displayStartTimestamp,
        displayEndTimestamp
      )
      const price = parseEther('0.4')
      await manager.connect(user2).newSpace(spaceMetadata)
      await manager
        .connect(user3)
        .offerPeriod(
          spaceMetadata,
          displayStartTimestamp,
          displayEndTimestamp,
          option({ value: price })
        )
      expect(await manager.connect(user3).cancelOffer(tokenId, option()))
        .to.emit(event, 'CancelOffer')
        .withArgs(tokenId)
      expect(await manager.offered(tokenId)).to.deep.equal([
        '',
        BigNumber.from(0),
        BigNumber.from(0),
        ADDRESS_ZERO,
        BigNumber.from(0),
      ])
    })

    it('should revert because the offer is not yours', async () => {
      const { now, factory, name } = await setupTests()
      const manager = await managerInstance(factory, name, now)

      const spaceMetadata = 'asfafkjksjfkajf'
      const displayStartTimestamp = now + 3600
      const displayEndTimestamp = now + 7200
      const tokenId = await manager.adId(
        spaceMetadata,
        displayStartTimestamp,
        displayEndTimestamp
      )
      const price = parseEther('0.4')
      await manager.connect(user2).newSpace(spaceMetadata)
      await manager
        .connect(user3)
        .offerPeriod(
          spaceMetadata,
          displayStartTimestamp,
          displayEndTimestamp,
          option({ value: price })
        )
      await expect(
        manager.connect(user4).cancelOffer(tokenId, option())
      ).to.be.revertedWith('KD116')
    })
  })

  describe('acceptOffer', async () => {
    it('should accept an offer', async () => {
      const { now, factory, name, pool, event } = await setupTests()
      const manager = await managerInstance(factory, name, now)

      const spaceMetadata = 'abi09nadu2brasfjl'
      const tokenMetadata = 'poiknfknajnjaer'
      const displayStartTimestamp = now + 3600
      const displayEndTimestamp = now + 7200
      const tokenId = await manager.adId(
        spaceMetadata,
        displayStartTimestamp,
        displayEndTimestamp
      )
      const price = parseEther('0.4')
      await manager.newSpace(spaceMetadata)
      await manager
        .connect(user3)
        .offerPeriod(
          spaceMetadata,
          displayStartTimestamp,
          displayEndTimestamp,
          option({ value: price })
        )
      expect(await manager.balance()).to.be.eq(parseEther('0.4'))
      expect(await manager.withdrawalAmount()).to.be.eq(parseEther('0'))

      expect(await manager.acceptOffer(tokenId, tokenMetadata, option()))
        .to.emit(event, 'AcceptOffer')
        .withArgs(
          tokenId,
          spaceMetadata,
          tokenMetadata,
          displayStartTimestamp,
          displayEndTimestamp,
          price
        )
      expect(await manager.tokenIdsOf(spaceMetadata)).to.deep.equal([tokenId])
      expect(await manager.balance()).to.be.eq(parseEther('0.36'))
      expect(await manager.withdrawalAmount()).to.be.eq(parseEther('0.36'))

      expect(await manager.periods(tokenId)).to.deep.equal([
        user3.address,
        spaceMetadata,
        tokenMetadata,
        BigNumber.from(now),
        BigNumber.from(now),
        BigNumber.from(displayStartTimestamp),
        BigNumber.from(displayEndTimestamp),
        3,
        price,
        price,
        true,
      ])
      expect(await pool.allPeriods(tokenId)).to.deep.equal([
        user3.address,
        spaceMetadata,
        tokenMetadata,
        BigNumber.from(now),
        BigNumber.from(now),
        BigNumber.from(displayStartTimestamp),
        BigNumber.from(displayEndTimestamp),
        3,
        price,
        price,
        true,
      ])
    })

    it('should revert because of the invalid tokenId', async () => {
      const { now, factory, name, event } = await setupTests()
      const manager = await managerInstance(factory, name, now)

      const spaceMetadata = 'abi09nadu2brasfjl'
      const tokenMetadata = 'poiknfknajnjaer'
      const displayStartTimestamp = now + 3600
      const displayEndTimestamp = now + 7200
      const wrongTokenId = await manager.adId(
        'asjkjkasjfkajkjfakjfkakdjak',
        displayStartTimestamp,
        displayEndTimestamp
      )
      const price = parseEther('0.4')
      await manager.newSpace(spaceMetadata)
      await manager
        .connect(user3)
        .offerPeriod(
          spaceMetadata,
          displayStartTimestamp,
          displayEndTimestamp,
          option({ value: price })
        )
      await expect(
        manager.acceptOffer(wrongTokenId, tokenMetadata, option())
      ).to.be.revertedWith('KD115')
    })

    it('should revert because the period has already bought and overlapped', async () => {
      const { now, factory, name, event } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const spaceMetadata = 'asfafkjksjfkajf'
      const tokenMetadata = 'poiknfknajnjaer'
      const saleEndTimestamp = now + 2400
      const displayStartTimestamp = now + 3600
      const displayEndTimestamp = now + 7200
      const pricing = 0
      const minPrice = parseEther('0.2')
      const tokenId = await manager.adId(
        spaceMetadata,
        displayStartTimestamp + 1000,
        displayEndTimestamp + 1000
      )

      const price = parseEther('0.4')
      await newPeriodWith(manager.connect(user2), {
        spaceMetadata: spaceMetadata,
        tokenMetadata: tokenMetadata,
        saleEndTimestamp: saleEndTimestamp,
        displayStartTimestamp: displayStartTimestamp,
        displayEndTimestamp: displayEndTimestamp,
        pricing: pricing,
        minPrice: minPrice,
      })
      await manager
        .connect(user3)
        .offerPeriod(
          spaceMetadata,
          displayStartTimestamp + 1000,
          displayEndTimestamp + 1000,
          option({ value: price })
        )

      await expect(
        manager.connect(user2).acceptOffer(tokenId, tokenMetadata, option())
      ).to.be.revertedWith('KD110')
    })
  })

  describe('buy', async () => {
    it('should buy a period', async () => {
      const { now, factory, name, event } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId } = await defaultPeriodProps(manager, now)

      const pricing = 0
      const price = parseEther('0.2')
      await newPeriodWith(manager, {
        now,
        pricing: pricing,
        minPrice: price,
      })

      expect(
        await buyWith(manager.connect(user3), {
          tokenId,
          value: price,
        })
      )
        .to.emit(event, 'Buy')
        .withArgs(tokenId, price, user3.address, now)
        .to.emit(event, 'TransferCustom')
        .withArgs(manager.address, user3.address, tokenId)
    })

    it('should revert because the pricing is not RRP', async () => {
      const { now, factory, name } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId } = await defaultPeriodProps(manager, now)
      const pricing = 1
      await newPeriodWith(manager, {
        now,
        pricing: pricing,
      })

      await expect(
        buyWith(manager.connect(user3), {
          tokenId,
        })
      ).to.be.revertedWith('KD120')
    })

    it('should revert because it has already sold', async () => {
      const { now, factory, name } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId } = await defaultPeriodProps(manager, now)
      const pricing = 0

      await newPeriodWith(manager, {
        now,
        pricing: pricing,
      })
      await buyWith(manager.connect(user3), {
        tokenId,
      })
      await expect(
        buyWith(manager.connect(user4), {
          tokenId,
        })
      ).to.be.revertedWith('KD121')
    })

    it('should revert because it has already sold', async () => {
      const { now, factory, name } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId } = await defaultPeriodProps(manager, now)
      const pricing = 0
      const price = parseEther('0.3')

      await newPeriodWith(manager, {
        now,
        pricing: pricing,
        minPrice: price,
      })
      await expect(
        buyWith(manager.connect(user3), {
          tokenId,
          value: parseEther('0.1'),
        })
      ).to.be.revertedWith('KD122')
    })

    it('should revert because the sender is the media EOA', async () => {
      const { now, factory, name } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId } = await defaultPeriodProps(manager, now)
      const pricing = 0
      const price = parseEther('0.3')

      await newPeriodWith(manager, {
        now,
        pricing: pricing,
        minPrice: price,
      })
      await expect(
        buyWith(manager.connect(user2), {
          tokenId,
          value: parseEther('0.1'),
        })
      ).to.be.revertedWith('KD014')
    })
  })

  describe('buyBasedOnTime', async () => {
    it('should buy a period', async () => {
      const { now, factory, name, event } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId } = await defaultPeriodProps(manager, now)

      const pricing = 1
      const price = parseEther('0.2')
      await newPeriodWith(manager, {
        now,
        pricing: pricing,
        minPrice: price,
      })

      // 2400/3600 -> 66% passed
      await manager.setTime(now + 2400)

      const currentPrice = await manager.currentPrice(tokenId)

      // slightly passed for its operation
      await manager.setTime(now + 2460)

      expect(
        await manager
          .connect(user3)
          .buyBasedOnTime(tokenId, option({ value: currentPrice }))
      )
        .to.emit(event, 'Buy')
        .withArgs(tokenId, currentPrice, user3.address, now + 2460)
        .to.emit(event, 'TransferCustom')
        .withArgs(manager.address, user3.address, tokenId)
    })

    it('should revert because the pricing is not DPBT', async () => {
      const { now, factory, name } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId } = await defaultPeriodProps(manager, now)
      const pricing = 2
      await newPeriodWith(manager, {
        now,
        pricing: pricing,
      })

      const currentPrice = await manager.currentPrice(tokenId)
      await expect(
        manager
          .connect(user3)
          .buyBasedOnTime(tokenId, option({ value: currentPrice }))
      ).to.be.revertedWith('KD123')
    })
  })

  describe('bid', async () => {
    it('should bid', async () => {
      const { now, factory, name, event } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId } = await defaultPeriodProps(manager, now)

      const pricing = 2
      const price = parseEther('0.2')
      await newPeriodWith(manager, {
        now,
        pricing: pricing,
        minPrice: price,
      })

      expect(
        await manager
          .connect(user3)
          .bid(tokenId, option({ value: parseEther('0.3') }))
      )
        .to.emit(event, 'Bid')
        .withArgs(tokenId, parseEther('0.3'), user3.address, now)
      expect(await manager.balance()).to.be.eq(parseEther('0.3'))
      expect(await manager.withdrawalAmount()).to.be.eq(parseEther('0'))
    })

    it('should bid twice by two members', async () => {
      const { now, factory, name, event } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId } = await defaultPeriodProps(manager, now)

      const pricing = 2
      const price = parseEther('0.2')
      await newPeriodWith(manager, {
        now,
        pricing: pricing,
        minPrice: price,
      })

      await manager
        .connect(user3)
        .bid(tokenId, option({ value: parseEther('0.3') }))
      await manager
        .connect(user4)
        .bid(tokenId, option({ value: parseEther('0.45') }))

      expect(await manager.balance()).to.be.eq(parseEther('0.45'))
      expect(await manager.withdrawalAmount()).to.be.eq(parseEther('0'))
    })

    it('should revert because it is not bidding', async () => {
      const { now, factory, name } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId } = await defaultPeriodProps(manager, now)

      const pricing = 0
      const price = parseEther('0.2')
      await newPeriodWith(manager, {
        now,
        pricing: pricing,
        minPrice: price,
      })

      await expect(
        manager
          .connect(user3)
          .bid(tokenId, option({ value: parseEther('0.3') }))
      ).to.be.revertedWith('KD124')
    })
  })

  describe('bidWithProposal', async () => {
    it('should bid with proposal', async () => {
      const { now, factory, name, event } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId } = await defaultPeriodProps(manager, now)
      const proposalMetadata = '3j34tw3jtwkejjauuwdsfj;lksja'
      const proposalMetadata2 = 'asfdjaij34rwerak13rwkeaj;lksja'

      const pricing = 4
      const minPrice = parseEther('0.2')
      await newPeriodWith(manager, {
        now,
        pricing,
        minPrice,
      })

      expect(
        await manager
          .connect(user3)
          .bidWithProposal(
            tokenId,
            proposalMetadata,
            option({ value: parseEther('0.3') })
          )
      )
        .to.emit(event, 'BidWithProposal')
        .withArgs(
          tokenId,
          parseEther('0.3'),
          user3.address,
          proposalMetadata,
          now
        )
      await manager
        .connect(user4)
        .bidWithProposal(
          tokenId,
          proposalMetadata2,
          option({ value: parseEther('0.25') })
        )
      expect(await manager.balance()).to.be.eq(parseEther('0.55'))
      expect(await manager.withdrawalAmount()).to.be.eq(parseEther('0'))
    })

    it('should revert because it is not bidding with proposal', async () => {
      const { now, factory, name } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId } = await defaultPeriodProps(manager, now)
      const proposalMetadata = '3j34tw3jtwkejjauuwdsfj;lksja'

      const wrongPricing = 2
      const minPrice = parseEther('0.2')
      await newPeriodWith(manager, {
        now,
        pricing: wrongPricing,
        minPrice,
      })

      await expect(
        manager
          .connect(user3)
          .bidWithProposal(
            tokenId,
            proposalMetadata,
            option({ value: parseEther('0.3') })
          )
      ).to.be.revertedWith('KD127')
    })

    it('should revert because it is under the minimum price', async () => {
      const { now, factory, name } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId } = await defaultPeriodProps(manager, now)
      const proposalMetadata = '3j34tw3jtwkejjauuwdsfj;lksja'

      const pricing = 4
      const minPrice = parseEther('0.2')
      await newPeriodWith(manager, {
        now,
        pricing,
        minPrice,
      })

      await expect(
        manager
          .connect(user3)
          .bidWithProposal(
            tokenId,
            proposalMetadata,
            option({ value: parseEther('0.19') })
          )
      ).to.be.revertedWith('KD122')
    })
  })

  describe('selectProposal', async () => {
    it('should select a proposal', async () => {
      const { now, factory, name, event } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId, saleEndTimestamp } = await defaultPeriodProps(
        manager,
        now
      )
      const proposalMetadata = '3j34tw3jtwkejjauuwdsfj;lksja'
      const proposalMetadata2 = 'asfdjaij34rwerak13rwkeaj;lksja'

      const pricing = 4
      const minPrice = parseEther('0.2')
      await newPeriodWith(manager, {
        now,
        pricing,
        minPrice,
        saleEndTimestamp,
      })
      await manager
        .connect(user3)
        .bidWithProposal(
          tokenId,
          proposalMetadata,
          option({ value: parseEther('0.3') })
        )
      await manager
        .connect(user4)
        .bidWithProposal(
          tokenId,
          proposalMetadata2,
          option({ value: parseEther('0.4') })
        )
      await manager.setTime(saleEndTimestamp + 1)

      expect(await manager.balance()).to.be.eq(parseEther('0.7'))
      expect(await manager.withdrawalAmount()).to.be.eq(parseEther('0'))

      expect(await manager.connect(user2).selectProposal(tokenId, 1, option()))
        .to.emit(event, 'SelectProposal')
        .withArgs(tokenId, user4.address)
      expect(await manager.balance()).to.be.eq(parseEther('0.36'))
      expect(await manager.withdrawalAmount()).to.be.eq(parseEther('0.36'))
    })

    it('should not select a proposal because the auction still continues', async () => {
      const { now, factory, name, event } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId, saleEndTimestamp } = await defaultPeriodProps(
        manager,
        now
      )
      const proposalMetadata = '3j34tw3jtwkejjauuwdsfj;lksja'
      const proposalMetadata2 = 'asfdjaij34rwerak13rwkeaj;lksja'

      const pricing = 4
      const minPrice = parseEther('0.2')
      await newPeriodWith(manager, {
        now,
        pricing,
        minPrice,
        saleEndTimestamp,
      })
      await manager
        .connect(user3)
        .bidWithProposal(
          tokenId,
          proposalMetadata,
          option({ value: parseEther('0.3') })
        )
      await manager
        .connect(user4)
        .bidWithProposal(
          tokenId,
          proposalMetadata2,
          option({ value: parseEther('0.25') })
        )
      await manager.setTime(saleEndTimestamp)
      await expect(
        manager.connect(user2).selectProposal(tokenId, 1, option())
      ).to.be.revertedWith('KD129')
    })

    it('should not select a proposal because of dubble actions', async () => {
      const { now, factory, name, event } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId, saleEndTimestamp } = await defaultPeriodProps(
        manager,
        now
      )
      const proposalMetadata = '3j34tw3jtwkejjauuwdsfj;lksja'
      const proposalMetadata2 = 'asfdjaij34rwerak13rwkeaj;lksja'

      const pricing = 4
      const minPrice = parseEther('0.2')
      await newPeriodWith(manager, {
        now,
        pricing,
        minPrice,
        saleEndTimestamp,
      })
      await manager
        .connect(user3)
        .bidWithProposal(
          tokenId,
          proposalMetadata,
          option({ value: parseEther('0.3') })
        )
      await manager
        .connect(user4)
        .bidWithProposal(
          tokenId,
          proposalMetadata2,
          option({ value: parseEther('0.25') })
        )
      await manager.setTime(saleEndTimestamp + 1)
      await manager.connect(user2).selectProposal(tokenId, 1, option())
      await expect(
        manager.connect(user2).selectProposal(tokenId, 1, option())
      ).to.be.revertedWith('KD114')
    })
  })

  describe('receiveToken', async () => {
    it('should receive token by the successful bidder', async () => {
      const { now, factory, name, event } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId } = await defaultPeriodProps(manager, now)

      const saleEndTimestamp = now + 2400
      const pricing = 2
      const price = parseEther('0.2')
      await newPeriodWith(manager, {
        now,
        saleEndTimestamp: saleEndTimestamp,
        pricing: pricing,
        minPrice: price,
      })
      await manager
        .connect(user3)
        .bid(tokenId, option({ value: parseEther('0.3') }))

      expect(await manager.balance()).to.be.eq(parseEther('0.3'))
      expect(await manager.withdrawalAmount()).to.be.eq(parseEther('0'))

      // passed the end timestamp of the sale
      await manager.setTime(now + 2410)

      expect(await manager.connect(user3).receiveToken(tokenId, option()))
        .to.emit(event, 'ReceiveToken')
        .withArgs(tokenId, parseEther('0.3'), user3.address, now + 2410)
        .to.emit(event, 'TransferCustom')
        .withArgs(manager.address, user3.address, tokenId)
      expect(await manager.balance()).to.be.eq(parseEther('0.27'))
      expect(await manager.withdrawalAmount()).to.be.eq(parseEther('0.27'))
    })

    it('should revert because the caller is not the successful bidder', async () => {
      const { now, factory, name, event } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId } = await defaultPeriodProps(manager, now)

      const saleEndTimestamp = now + 2400
      const pricing = 2
      const price = parseEther('0.2')
      await newPeriodWith(manager, {
        now,
        saleEndTimestamp: saleEndTimestamp,
        pricing: pricing,
        minPrice: price,
      })
      await manager
        .connect(user3)
        .bid(tokenId, option({ value: parseEther('0.3') }))

      // passed the end timestamp of the sale
      await manager.setTime(now + 2410)

      await expect(
        manager.connect(user4).receiveToken(tokenId, option())
      ).to.be.revertedWith('KD126')
    })

    it('should revert because the auction has not ended yet', async () => {
      const { now, factory, name, event } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId } = await defaultPeriodProps(manager, now)

      const saleEndTimestamp = now + 2400
      const pricing = 2
      const price = parseEther('0.2')
      await newPeriodWith(manager, {
        now,
        saleEndTimestamp: saleEndTimestamp,
        pricing: pricing,
        minPrice: price,
      })
      await manager
        .connect(user3)
        .bid(tokenId, option({ value: parseEther('0.3') }))

      await expect(
        manager.connect(user3).receiveToken(tokenId, option())
      ).to.be.revertedWith('KD125')
    })
  })

  describe('pushToSuccessfulBidder', async () => {
    it('should push a token to the successful bidder', async () => {
      const { now, factory, name, event } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId } = await defaultPeriodProps(manager, now)

      const saleEndTimestamp = now + 2400
      const pricing = 2
      const price = parseEther('0.2')
      await newPeriodWith(manager, {
        now,
        saleEndTimestamp: saleEndTimestamp,
        pricing: pricing,
        minPrice: price,
      })
      await manager
        .connect(user3)
        .bid(tokenId, option({ value: parseEther('0.3') }))

      expect(await manager.balance()).to.be.eq(parseEther('0.3'))
      expect(await manager.withdrawalAmount()).to.be.eq(parseEther('0'))

      // passed the end timestamp of the sale
      await manager.setTime(now + 2410)

      expect(
        await manager.connect(user2).pushToSuccessfulBidder(tokenId, option())
      )
        .to.emit(event, 'ReceiveToken')
        .withArgs(tokenId, parseEther('0.3'), user3.address, now + 2410)
        .to.emit(event, 'TransferCustom')
        .withArgs(manager.address, user3.address, tokenId)
      expect(await manager.balance()).to.be.eq(parseEther('0.27'))
      expect(await manager.withdrawalAmount()).to.be.eq(parseEther('0.27'))
      expect(await manager.ownerOf(tokenId)).to.be.eq(user3.address)
    })
  })

  describe('withdraw', async () => {
    it('should withdraw the fund after a user bought', async () => {
      const { now, factory, name, event } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId } = await defaultPeriodProps(manager, now)

      const pricing = 0
      const price = parseEther('0.2')
      await newPeriodWith(manager, {
        now,
        pricing: pricing,
        minPrice: price,
      })
      await buyWith(manager.connect(user3), {
        tokenId,
        value: price,
      })

      expect(await manager.withdraw())
        .to.emit(event, 'Withdraw')
        .withArgs(parseEther('0.18'))
    })

    // TODO: withdarawal amount
  })

  describe('propose', async () => {
    it('should propose to the right you bought', async () => {
      const { now, factory, name, event } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId } = await defaultPeriodProps(manager, now)

      const proposalMetadata = 'asfdjakjajk3rq35jqwejrqk'
      await newPeriodWith(manager, { now })
      await buyWith(manager.connect(user3), { tokenId })

      expect(
        await manager
          .connect(user3)
          .propose(tokenId, proposalMetadata, option())
      )
        .to.emit(event, 'Propose')
        .withArgs(tokenId, proposalMetadata)
      expect(await manager.proposed(tokenId)).to.deep.equal([
        proposalMetadata,
        user3.address,
      ])
    })

    it('should revert because the token is not yours', async () => {
      const { now, factory, name, event } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId } = await defaultPeriodProps(manager, now)

      const proposalMetadata = 'asfdjakjajk3rq35jqwejrqk'
      await newPeriodWith(manager, { now })
      await buyWith(manager.connect(user3), { tokenId })

      await expect(
        manager.connect(user4).propose(tokenId, proposalMetadata, option())
      ).to.be.revertedWith('KD012')
    })
  })

  describe('acceptProposal', async () => {
    it('should accept a proposal', async () => {
      const { now, factory, name, event } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId } = await defaultPeriodProps(manager, now)

      const proposalMetadata = 'asfdjakjajk3rq35jqwejrqk'
      await newPeriodWith(manager, { now })
      await buyWith(manager.connect(user3), { tokenId })
      await manager.connect(user3).propose(tokenId, proposalMetadata)

      expect(await manager.acceptProposal(tokenId, option()))
        .to.emit(event, 'AcceptProposal')
        .withArgs(tokenId, proposalMetadata)
      expect(await manager.proposed(tokenId)).to.deep.equal(['', user3.address])
      expect(await manager.ownerOf(tokenId)).to.be.eq(user3.address)
    })

    it('should revert because it has already proposed', async () => {
      const { now, factory, name } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId } = await defaultPeriodProps(manager, now)

      const proposalMetadata = 'asfdjakjajk3rq35jqwejrqk'
      await newPeriodWith(manager, { now })
      await buyWith(manager.connect(user3), { tokenId })
      await manager.connect(user3).propose(tokenId, proposalMetadata)
      await manager.acceptProposal(tokenId, option())

      await expect(
        manager.acceptProposal(tokenId, option())
      ).to.be.revertedWith('KD130')
    })

    it('should revert because the token has transferred to others', async () => {
      const { now, factory, name } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId } = await defaultPeriodProps(manager, now)

      const proposalMetadata = 'asfdjakjajk3rq35jqwejrqk'
      await newPeriodWith(manager, { now })
      await buyWith(manager.connect(user3), { tokenId })
      await manager.connect(user3).propose(tokenId, proposalMetadata)
      await manager
        .connect(user3)
        .transferFrom(user3.address, user4.address, tokenId)

      await expect(
        manager.acceptProposal(tokenId, option())
      ).to.be.revertedWith('KD131')
    })
  })

  describe('denyProposal', async () => {
    it('should deny a proposal', async () => {
      const { now, factory, name, event } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId } = await defaultPeriodProps(manager, now)

      const proposalMetadata = 'asfdjakjajk3rq35jqwejrqk'
      await newPeriodWith(manager, { now })
      await buyWith(manager.connect(user3), { tokenId })
      await manager.connect(user3).propose(tokenId, proposalMetadata)

      const deniedReason =
        'This is a violence image a bit. We can not accept, sorry.'
      const offensive = true
      expect(
        await manager.denyProposal(tokenId, deniedReason, offensive, option())
      )
        .to.emit(event, 'DenyProposal')
        .withArgs(tokenId, proposalMetadata, deniedReason, offensive)
    })

    it('should revert because there is not any proposals', async () => {
      const { now, factory, name } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId } = await defaultPeriodProps(manager, now)

      const deniedReason =
        'This is a violence image a bit. We can not accept, sorry.'
      const offensive = true
      await newPeriodWith(manager, { now })
      await buyWith(manager.connect(user3), { tokenId })

      await expect(
        manager.denyProposal(tokenId, deniedReason, offensive, option())
      ).to.be.revertedWith('KD130')
    })
  })

  describe('display', async () => {
    it('should display', async () => {
      const { now, factory, name, event } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId, spaceMetadata } = await defaultPeriodProps(manager, now)

      const proposalMetadata = 'asfdjakjajk3rq35jqwejrqk'
      await newPeriodWith(manager, { now })
      await buyWith(manager.connect(user3), { tokenId })
      await manager.connect(user3).propose(tokenId, proposalMetadata)
      await manager.acceptProposal(tokenId, option())

      // passed to the start of displaying
      await manager.setTime(now + 4000)

      expect(await manager.display(spaceMetadata)).to.deep.equal([
        proposalMetadata,
        tokenId,
      ])
    })

    it('should not display before it starts', async () => {
      const { now, factory, name, event } = await setupTests()
      const manager = await managerInstance(factory, name, now)
      const { tokenId, spaceMetadata } = await defaultPeriodProps(manager, now)

      const proposalMetadata = 'asfdjakjajk3rq35jqwejrqk'
      await newPeriodWith(manager, { now })
      await buyWith(manager.connect(user3), { tokenId })
      await manager.connect(user3).propose(tokenId, proposalMetadata)
      await manager.acceptProposal(tokenId, option())

      expect(await manager.display(spaceMetadata)).to.deep.equal([
        '',
        BigNumber.from(0),
      ])
    })
  })
})

export type NewPeriodProps = {
  now?: number
  spaceMetadata?: string
  tokenMetadata?: string
  saleEndTimestamp?: number
  displayStartTimestamp?: number
  displayEndTimestamp?: number
  pricing?: number
  minPrice?: BigNumber
}

export const newPeriodWith = async (
  manager: ethers.Contract,
  props?: NewPeriodProps
) => {
  const now = props?.now ? props.now : Date.now()
  const defaults = await defaultPeriodProps(manager, now)
  return await manager.newPeriod(
    props?.spaceMetadata ? props.spaceMetadata : defaults.spaceMetadata,
    props?.tokenMetadata ? props.tokenMetadata : 'poiknfknajnjaer',
    props?.saleEndTimestamp
      ? props.saleEndTimestamp
      : defaults.saleEndTimestamp,
    props?.displayStartTimestamp
      ? props.displayStartTimestamp
      : defaults.displayStartTimestamp,
    props?.displayEndTimestamp
      ? props.displayEndTimestamp
      : defaults.displayEndTimestamp,
    props?.pricing ? props.pricing : 0,
    props?.minPrice ? props.minPrice : parseEther('0.1'),
    option()
  )
}

const defaultPeriodProps = async (manager: ethers.Contract, now: number) => {
  const spaceMetadata = 'abi09nadu2brasfjl'
  const saleEndTimestamp = now + 2400
  const displayStartTimestamp = now + 3600
  const displayEndTimestamp = now + 7200
  const tokenId = await manager.adId(
    spaceMetadata,
    displayStartTimestamp,
    displayEndTimestamp
  )
  return {
    spaceMetadata,
    saleEndTimestamp,
    displayStartTimestamp,
    displayEndTimestamp,
    tokenId,
  }
}

export type BuyProps = {
  tokenId: number
  value?: BigNumber
}

export const buyWith = async (manager: ethers.Contract, props: BuyProps) => {
  return await manager.buy(
    props.tokenId,
    option({ value: props.value ? props.value : parseEther('0.1') })
  )
}
