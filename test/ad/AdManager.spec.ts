import { expect } from 'chai'
import { BigNumber } from 'ethers'
import { deployments, network, waffle } from 'hardhat'
import { ADDRESS_ZERO } from '../utils/address'
import { parseEth } from './../utils/number'
import {
  getAdManagerContract,
  getDistributionRightContract,
} from './../utils/setup'

describe('AdManager', async () => {
  const [user1, user2, user3, user4, user5] = waffle.provider.getWallets()

  const setupTests = deployments.createFixture(async ({ deployments }) => {
    await deployments.fixture()
    return {
      manager: await getAdManagerContract(),
      right: await getDistributionRightContract(),
    }
  })

  describe('newPost', async () => {
    it('should new a post', async () => {
      const { manager } = await setupTests()

      const postMetadata = 'abi09nadu2brasfjl'
      const initialPrice = 10
      const periodHours = 60 * 60 * 24 * 3 // 72 hours

      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const postId = await manager.computePostId(
        postMetadata,
        (await waffle.provider.getBlockNumber()) + 1
      )

      expect(await manager.newPost(postMetadata, initialPrice, periodHours))
        .to.emit(manager, 'NewPost')
        .withArgs(
          postId,
          user1.address,
          postMetadata,
          initialPrice,
          periodHours,
          now + 1,
          now + 1 + periodHours
        )
      expect(await manager.allPosts(postId)).to.deep.equal([
        postId,
        user1.address,
        postMetadata,
        BigNumber.from(initialPrice),
        BigNumber.from(periodHours),
        BigNumber.from(now + 1),
        BigNumber.from(now + 1 + periodHours),
        ADDRESS_ZERO,
      ])
    })
  })

  describe('bid', async () => {
    it('should bit to a post', async () => {
      const { manager } = await setupTests()
      const managerByUser2 = manager.connect(user2)

      const postMetadata = 'abi09nadu2brasfjl'
      const initialPrice = 10
      const periodHours = 60 * 60 * 24 * 3 // 72 hours

      const bidMetadata = 'xxxdafakjkjfaj;jf'
      const bitPrice = parseEth(1.5)

      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const postId = await manager.computePostId(
        postMetadata,
        (await waffle.provider.getBlockNumber()) + 1
      )
      const bidId = await manager.computeBidId(postId, bidMetadata)

      await manager.newPost(postMetadata, initialPrice, periodHours)
      expect(await managerByUser2.bid(postId, bidMetadata, { value: bitPrice }))
        .to.emit(manager, 'Bid')
        .withArgs(bidId, postId, user2.address, bitPrice, bidMetadata)

      expect(await manager.bidderInfo(bidId)).to.deep.equal([
        bidId,
        postId,
        user2.address,
        bitPrice,
        bidMetadata,
      ])
      expect(await manager.bidderList(postId)).to.deep.equal([bidId])
    })
  })

  describe('close', async () => {
    it('should close after the period', async () => {
      const { manager } = await setupTests()
      const managerByUser2 = manager.connect(user2)
      const managerByUser3 = manager.connect(user3)

      const postMetadata = 'abi09nadu2brasfjl'
      const initialPrice = 10
      const periodHours = 60 * 60 * 24 * 3 // 72 hours

      const bidMetadata1 = 'xxxdafakjkjfaj;jf'
      const bitPrice1 = parseEth(1.5)

      const bidMetadata2 = 'saedafakjkjfaj;jf'
      const bitPrice2 = parseEth(2.5)

      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const postId = await manager.computePostId(
        postMetadata,
        (await waffle.provider.getBlockNumber()) + 1
      )
      const bidId1 = await manager.computeBidId(postId, bidMetadata1)

      await manager.newPost(postMetadata, initialPrice, periodHours)
      await managerByUser2.bid(postId, bidMetadata1, { value: bitPrice1 })
      await managerByUser3.bid(postId, bidMetadata2, { value: bitPrice2 })

      await network.provider.send('evm_increaseTime', [
        periodHours + periodHours,
      ])
      await network.provider.send('evm_mine')

      expect(await manager.close(bidId1))
        .to.emit(manager, 'Close')
        .withArgs(bidId1, postId, user2.address, bitPrice1, bidMetadata1)
    })
  })
})
