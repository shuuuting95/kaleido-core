import { expect } from 'chai'
import { BigNumber } from 'ethers'
import { deployments, network, waffle } from 'hardhat'
import { ADDRESS_ZERO } from '../utils/address'
import { parseEth } from './../utils/number'
import {
  getAdManagerContract,
  getAdPoolContract,
  getDistributionRightContract,
  getVaultContract,
} from './../utils/setup'

describe('AdManager', async () => {
  const [user1, user2, user3, user4, user5] = waffle.provider.getWallets()

  const setupTests = deployments.createFixture(async ({ deployments }) => {
    await deployments.fixture()
    return {
      manager: await getAdManagerContract(),
      right: await getDistributionRightContract(),
      vault: await getVaultContract(),
      pool: await getAdPoolContract(),
    }
  })

  describe('newPost', async () => {
    it('should new a post', async () => {
      const { manager, right } = await setupTests()

      const postMetadata = 'abi09nadu2brasfjl'
      const width = 300
      const height = 500
      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const fromTimestamp = now + 3600
      const toTimestamp = now + 7200

      const postId = await manager.nextPostId()
      expect(
        await manager.newPost(
          postMetadata,
          width,
          height,
          fromTimestamp,
          toTimestamp
        )
      )
        .to.emit(manager, 'NewPost')
        .withArgs(
          postId,
          user1.address,
          postMetadata,
          width,
          height,
          fromTimestamp,
          toTimestamp
        )
        .to.emit(right, 'Transfer')
        .withArgs(ADDRESS_ZERO, user1.address, postId)

      expect(await manager.allPosts(postId)).to.deep.equal([
        postId,
        user1.address,
        postMetadata,
        BigNumber.from(width),
        BigNumber.from(height),
        BigNumber.from(fromTimestamp),
        BigNumber.from(toTimestamp),
        BigNumber.from(0),
      ])
    })
  })

  describe('bid', async () => {
    it('should bit to a post', async () => {
      const { manager } = await setupTests()
      const managerByUser2 = manager.connect(user2)

      const postMetadata = 'abi09nadu2brasfjl'
      const width = 300
      const height = 500
      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const fromTimestamp = now + 3600
      const toTimestamp = now + 7200
      const postId = await manager.nextPostId()

      const bidMetadata = 'xxxdafakjkjfaj;jf'
      const originalLink = 'https://coinmedia.io/'
      const bitPrice = parseEth(1.5)
      const bidId = await manager.nextBidId()

      await manager.newPost(
        postMetadata,
        width,
        height,
        fromTimestamp,
        toTimestamp
      )
      expect(
        await managerByUser2.bid(postId, bidMetadata, originalLink, {
          value: bitPrice,
        })
      )
        .to.emit(manager, 'Bid')
        .withArgs(
          bidId,
          postId,
          user2.address,
          bitPrice,
          bidMetadata,
          originalLink
        )
      expect(await manager.bidderInfo(bidId)).to.deep.equal([
        bidId,
        postId,
        user2.address,
        bitPrice,
        bidMetadata,
        originalLink,
        0,
      ])
      expect(await manager.bidderList(postId)).to.deep.equal([bidId])
    })
  })

  describe('close', async () => {
    it('should close after the period', async () => {
      const { manager, right, vault } = await setupTests()
      const managerByUser2 = manager.connect(user2)
      const managerByUser3 = manager.connect(user3)

      const postMetadata = 'abi09nadu2brasfjl'
      const width = 300
      const height = 500
      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const fromTimestamp = now + 3600
      const toTimestamp = now + 7200
      const postId = await manager.nextPostId()
      await manager.newPost(
        postMetadata,
        width,
        height,
        fromTimestamp,
        toTimestamp
      )

      const bidMetadata2 = 'xxxdafakjkjfaj;jf'
      const originalLink2 = 'https://coinmedia.io/'
      const bitPrice2 = parseEth(100)
      const bidId2 = await manager.nextBidId()
      await managerByUser2.bid(postId, bidMetadata2, originalLink2, {
        value: bitPrice2,
      })

      const bidMetadata3 = 'saedafakjkjfaj;jf'
      const originalLink3 = 'https://coinmedia.io/'
      const bitPrice3 = parseEth(200)
      await managerByUser3.bid(postId, bidMetadata3, originalLink3, {
        value: bitPrice3,
      })

      const user1BalanceBeforeClose = await user1.getBalance()
      const user2BalanceBeforeClose = await user2.getBalance()

      expect(await manager.close(bidId2))
        .to.emit(manager, 'Close')
        .withArgs(bidId2, postId, user2.address, bitPrice2, bidMetadata2)
        .to.emit(right, 'Transfer')
        .withArgs(user1.address, user2.address, postId)
        .to.emit(vault, 'Received')
        .withArgs(manager.address, parseEth(10))
      const user1BalanceAfterClose = await user1.getBalance()
      const user2BalanceAfterClose = await user2.getBalance()

      const user1BalanceDiff = Number(
        user1BalanceAfterClose.sub(user1BalanceBeforeClose)
      )
      const user2BalanceDiff = Number(
        user2BalanceAfterClose.sub(user2BalanceBeforeClose)
      )
      expect(user1BalanceDiff).to.be.lt(Number(parseEth(90.0)))
      expect(user1BalanceDiff).to.be.gt(Number(parseEth(89.9)))
      expect(user2BalanceDiff).to.be.eq(0)
      expect(await vault.balance()).to.be.eq(parseEth(10))

      expect(await right.ownerOf(postId)).to.be.eq(user2.address)
      expect(await right.tokenURI(postId)).to.be.eq(`ipfs://${postMetadata}`)
    })
  })

  describe('refund', async () => {
    it('should refund after the period', async () => {
      const { manager, right } = await setupTests()
      const managerByUser2 = manager.connect(user2)
      const managerByUser3 = manager.connect(user3)

      const postMetadata = 'abi09nadu2brasfjl'
      const width = 300
      const height = 500
      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const fromTimestamp = now + 3600
      const toTimestamp = now + 7200
      const postId = await manager.nextPostId()

      await manager.newPost(
        postMetadata,
        width,
        height,
        fromTimestamp,
        toTimestamp
      )

      const bidMetadata2 = 'xxxdafakjkjfaj;jf'
      const originalLink2 = 'https://coinmedia.io/'
      const bitPrice2 = parseEth(100)
      const bidId2 = await manager.nextBidId()
      await managerByUser2.bid(postId, bidMetadata2, originalLink2, {
        value: bitPrice2,
      })

      const bidMetadata3 = 'saedafakjkjfaj;jf'
      const originalLink3 = 'https://coinmedia.io/'
      const bitPrice3 = parseEth(200)
      const bidId3 = await manager.nextBidId()
      await managerByUser3.bid(postId, bidMetadata3, originalLink3, {
        value: bitPrice3,
      })
      await manager.close(bidId2)

      const user3BalanceBeforeClose = await user3.getBalance()

      expect(await managerByUser3.refund(bidId3))
        .to.emit(manager, 'Refund')
        .withArgs(bidId3, postId, user3.address, bitPrice3)

      const user3BalanceAfterClose = await user3.getBalance()
      const user3BalanceDiff = Number(
        user3BalanceAfterClose.sub(user3BalanceBeforeClose)
      )
      expect(user3BalanceDiff).to.be.lt(Number(parseEth(200)))
      expect(user3BalanceDiff).to.be.gt(Number(parseEth(199.9)))
    })
  })

  describe('withdraw', async () => {
    it('should withdraw after the close', async () => {
      const { manager, vault } = await setupTests()
      const managerByUser2 = manager.connect(user2)
      const managerByUser3 = manager.connect(user3)

      const postMetadata = 'abi09nadu2brasfjl'
      const width = 300
      const height = 500
      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const fromTimestamp = now + 3600
      const toTimestamp = now + 7200
      const postId = await manager.nextPostId()
      await manager.newPost(
        postMetadata,
        width,
        height,
        fromTimestamp,
        toTimestamp
      )

      const bidMetadata2 = 'xxxdafakjkjfaj;jf'
      const originalLink2 = 'https://coinmedia.io/'
      const bitPrice2 = parseEth(100)
      const bidId2 = await manager.nextBidId()
      await managerByUser2.bid(postId, bidMetadata2, originalLink2, {
        value: bitPrice2,
      })

      const bidMetadata3 = 'saedafakjkjfaj;jf'
      const originalLink3 = 'https://coinmedia.io/'
      const bitPrice3 = parseEth(200)
      await managerByUser3.bid(postId, bidMetadata3, originalLink3, {
        value: bitPrice3,
      })
      await manager.close(bidId2)

      const user1BalanceBeforeWithdraw = await user1.getBalance()
      expect(await vault.balance()).to.be.eq(parseEth(10))
      expect(await vault.withdraw(parseEth(9)))
        .to.emit(vault, 'Withdraw')
        .withArgs(user1.address, parseEth(9))
      expect(await vault.balance()).to.be.eq(parseEth(1))
      const user1BalanceAfterWithdraw = await user1.getBalance()
      const user1BalanceDiff = Number(
        user1BalanceAfterWithdraw.sub(user1BalanceBeforeWithdraw)
      )
      expect(user1BalanceDiff).to.be.lt(Number(parseEth(9.0)))
      expect(user1BalanceDiff).to.be.gt(Number(parseEth(8.9)))
    })
  })

  describe('call', async () => {
    it('should call a bid', async () => {
      const { manager, vault, pool } = await setupTests()
      const managerByUser2 = manager.connect(user2)
      const managerByUser3 = manager.connect(user3)

      const postMetadata = 'abi09nadu2brasfjl'
      const width = 300
      const height = 500
      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const fromTimestamp = now + 3600
      const toTimestamp = now + 7200
      const postId = await manager.nextPostId()

      await manager.newPost(
        postMetadata,
        width,
        height,
        fromTimestamp,
        toTimestamp
      )
      const bidMetadata2 = ''
      const originalLink2 = ''
      const bitPrice2 = parseEth(100)
      const bidId2 = await manager.nextBidId()
      await managerByUser2.bid(postId, bidMetadata2, originalLink2, {
        value: bitPrice2,
      })

      const bidMetadata3 = 'saedafakjkjfaj;jf'
      const originalLink3 = ''
      const bitPrice3 = parseEth(200)
      await managerByUser3.bid(postId, bidMetadata3, originalLink3, {
        value: bitPrice3,
      })
      expect(await manager.call(bidId2))
        .to.emit(manager, 'Call')
        .withArgs(bidId2, postId, user2.address, bitPrice2)
    })
  })

  describe('propose', async () => {
    it('should propose on the reservation', async () => {
      const { manager, vault, pool } = await setupTests()
      const managerByUser2 = manager.connect(user2)
      const managerByUser3 = manager.connect(user3)

      const postMetadata = 'abi09nadu2brasfjl'
      const width = 300
      const height = 500
      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const fromTimestamp = now + 3600
      const toTimestamp = now + 7200
      const postId = await manager.nextPostId()

      await manager.newPost(
        postMetadata,
        width,
        height,
        fromTimestamp,
        toTimestamp
      )
      const bidMetadata2 = ''
      const originalLink2 = ''
      const bitPrice2 = parseEth(100)
      const bidId2 = await manager.nextBidId()
      await managerByUser2.bid(postId, bidMetadata2, originalLink2, {
        value: bitPrice2,
      })

      const bidMetadata3 = 'saedafakjkjfaj;jf'
      const originalLink3 = ''
      const bitPrice3 = parseEth(200)
      await managerByUser3.bid(postId, bidMetadata3, originalLink3, {
        value: bitPrice3,
      })
      await manager.call(bidId2)

      const proposedMetadata = 'kjfkajlfjaji3j'
      const proposedLink = 'https://www.example.com'
      expect(
        await managerByUser2.propose(postId, proposedMetadata, proposedLink)
      )
        .to.emit(manager, 'Propose')
        .withArgs(bidId2, postId, proposedMetadata, proposedLink)
    })
  })

  describe('recall', async () => {
    it('should recall the bid', async () => {
      const { manager, vault, pool } = await setupTests()
      const managerByUser2 = manager.connect(user2)
      const managerByUser3 = manager.connect(user3)

      const postMetadata = 'abi09nadu2brasfjl'
      const width = 300
      const height = 500
      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const fromTimestamp = now + 3600
      const toTimestamp = now + 7200
      const postId = await manager.nextPostId()

      await manager.newPost(
        postMetadata,
        width,
        height,
        fromTimestamp,
        toTimestamp
      )
      const bidMetadata2 = ''
      const originalLink2 = ''
      const bitPrice2 = parseEth(100)
      const bidId2 = await manager.nextBidId()
      await managerByUser2.bid(postId, bidMetadata2, originalLink2, {
        value: bitPrice2,
      })

      const bidMetadata3 = 'saedafakjkjfaj;jf'
      const originalLink3 = ''
      const bitPrice3 = parseEth(200)
      const bidId3 = await manager.nextBidId()
      await managerByUser3.bid(postId, bidMetadata3, originalLink3, {
        value: bitPrice3,
      })
      await manager.call(bidId2)

      const proposedMetadata = 'kjfkajlfjaji3j'
      const proposedLink = 'https://www.example.com'
      await managerByUser2.propose(postId, proposedMetadata, proposedLink)

      expect(await manager.recall(postId, bidId2, bidId3))
        .to.emit(manager, 'Recall')
        .withArgs(postId, bidId2, bidId3)
    })
  })

  describe('accept', async () => {
    it('should accept the proposal', async () => {
      const { manager, vault, pool } = await setupTests()
      const managerByUser2 = manager.connect(user2)
      const managerByUser3 = manager.connect(user3)

      const postMetadata = 'abi09nadu2brasfjl'
      const width = 300
      const height = 500
      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const fromTimestamp = now + 3600
      const toTimestamp = now + 7200
      const postId = await manager.nextPostId()

      await manager.newPost(
        postMetadata,
        width,
        height,
        fromTimestamp,
        toTimestamp
      )
      const bidMetadata2 = ''
      const originalLink2 = ''
      const bitPrice2 = parseEth(100)
      const bidId2 = await manager.nextBidId()
      await managerByUser2.bid(postId, bidMetadata2, originalLink2, {
        value: bitPrice2,
      })

      const bidMetadata3 = 'saedafakjkjfaj;jf'
      const originalLink3 = ''
      const bitPrice3 = parseEth(200)
      const bidId3 = await manager.nextBidId()
      await managerByUser3.bid(postId, bidMetadata3, originalLink3, {
        value: bitPrice3,
      })
      await manager.call(bidId2)

      const proposedMetadata = 'kjfkajlfjaji3j'
      const proposedLink = 'https://www.example.com'
      await managerByUser2.propose(postId, proposedMetadata, proposedLink)

      expect(await manager.accept(postId))
        .to.emit(manager, 'Accept')
        .withArgs(postId, bidId2)
    })
  })
})
