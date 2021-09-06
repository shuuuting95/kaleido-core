import { expect } from 'chai'
import { BigNumber } from 'ethers'
import { deployments, network, waffle } from 'hardhat'
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
      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const fromTimestamp = now + 3600
      const toTimestamp = now + 7200

      const postId = await manager.nextPostId()
      expect(await manager.newPost(postMetadata, fromTimestamp, toTimestamp))
        .to.emit(manager, 'NewPost')
        .withArgs(
          postId,
          user1.address,
          postMetadata,
          fromTimestamp,
          toTimestamp
        )

      expect(await manager.allPosts(postId)).to.deep.equal([
        postId,
        user1.address,
        postMetadata,
        BigNumber.from(fromTimestamp),
        BigNumber.from(toTimestamp),
        BigNumber.from(0),
      ])
    })
    it('should have valid periods', async () => {
      const { manager } = await setupTests()

      const postMetadata = 'abi09nadu2brasfjl'
      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const fromTimestamp = now + 7200
      const toTimestamp = now + 3600

      await expect(
        manager.newPost(postMetadata, fromTimestamp, toTimestamp)
      ).to.be.revertedWith('AD101')
    })
    it('should have separated durations', async () => {
      const { manager, right } = await setupTests()

      const postMetadata = 'abi09nadu2brasfjl'
      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const fromTimestamp = now + 3600
      const toTimestamp = now + 7200
      await manager.newPost(postMetadata, fromTimestamp, toTimestamp)
      const cases = [
        {
          from: fromTimestamp,
          to: toTimestamp,
        },
        {
          from: fromTimestamp + 1,
          to: toTimestamp + 1,
        },
        {
          from: fromTimestamp - 1,
          to: toTimestamp - 1,
        },
        {
          from: fromTimestamp - 1,
          to: fromTimestamp,
        },
        {
          from: toTimestamp,
          to: toTimestamp + 1,
        },
      ]
      cases.forEach((c) => {
        expect(manager.newPost(postMetadata, c.from, c.to)).to.be.revertedWith(
          'AD101'
        )
      })
    })
    it('doesnt have to be separated durations with different metadata', async () => {
      const { manager } = await setupTests()

      const postMetadata = 'abi09nadu2brasfjl'
      const anotherMetadata = 'xxxdafakjkjfaj;jf'
      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const fromTimestamp = now + 3600
      const toTimestamp = now + 7200
      await manager.newPost(postMetadata, fromTimestamp, toTimestamp)
      const postId = await manager.nextPostId()
      expect(await manager.newPost(anotherMetadata, fromTimestamp, toTimestamp))
        .to.emit(manager, 'NewPost')
        .withArgs(
          postId,
          user1.address,
          anotherMetadata,
          fromTimestamp,
          toTimestamp
        )
    })
  })

  describe('bid', async () => {
    it('should be disabled after expiration', async () => {
      const { manager } = await setupTests()
      const managerByUser2 = manager.connect(user2)

      const postMetadata = 'abi09nadu2brasfjl'
      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const fromTimestamp = now - 1000
      const toTimestamp = now + 1800
      const postId = await manager.nextPostId()

      const bidMetadata = 'xxxdafakjkjfaj;jf'
      const bitPrice = parseEth(1.5)
      const bidId = await manager.nextBidId()
      await manager.newPost(postMetadata, fromTimestamp, toTimestamp)
      await network.provider.send('evm_setNextBlockTimestamp', [now + 3600])
      await expect(
        managerByUser2.bid(postId, bidMetadata, {
          value: bitPrice,
        })
      ).to.be.revertedWith('AD108')
    })
    it('should bit to a post', async () => {
      const { manager } = await setupTests()
      const managerByUser2 = manager.connect(user2)

      const postMetadata = 'abi09nadu2brasfjl'
      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const fromTimestamp = now + 3600
      const toTimestamp = now + 7200
      const postId = await manager.nextPostId()

      const bidMetadata = 'xxxdafakjkjfaj;jf'
      const bitPrice = parseEth(1.5)
      const bidId = await manager.nextBidId()

      await manager.newPost(postMetadata, fromTimestamp, toTimestamp)
      expect(
        await managerByUser2.bid(postId, bidMetadata, {
          value: bitPrice,
        })
      )
        .to.emit(manager, 'Bid')
        .withArgs(bidId, postId, user2.address, bitPrice, bidMetadata)
      expect(await manager.bidderInfo(bidId)).to.deep.equal([
        bidId,
        postId,
        user2.address,
        bitPrice,
        bidMetadata,
        1,
      ])
      expect(await manager.bidderList(postId)).to.deep.equal([bidId])
    })
    it('can be done unless a successful bid does not exist', async () => {
      const { manager } = await setupTests()
      const managerByUser2 = manager.connect(user2)

      const postMetadata = 'abi09nadu2brasfjl'
      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const fromTimestamp = now + 3600
      const toTimestamp = now + 7200
      const postId = await manager.nextPostId()

      const bidMetadata = 'xxxdafakjkjfaj;jf'
      const bitPrice = parseEth(1.5)
      const bidId = await manager.nextBidId()

      await manager.newPost(postMetadata, fromTimestamp, toTimestamp)

      await managerByUser2.book(postId, {
        value: bitPrice,
      })
      await manager.call(bidId)
      await expect(
        managerByUser2.bid(postId, bidMetadata, {
          value: bitPrice,
        })
      ).to.be.revertedWith('AD102')
    })
  })

  describe('book', async () => {
    it('should be disabled after expiration', async () => {
      const { manager } = await setupTests()
      const managerByUser2 = manager.connect(user2)

      const postMetadata = 'abi09nadu2brasfjl'
      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const fromTimestamp = now - 1800
      const toTimestamp = now + 1800
      const postId = await manager.nextPostId()

      const bookPrice = parseEth(1.5)

      await manager.newPost(postMetadata, fromTimestamp, toTimestamp)
      await network.provider.send('evm_setNextBlockTimestamp', [now + 3600])

      await expect(
        managerByUser2.book(postId, {
          value: bookPrice,
        })
      ).to.be.revertedWith('AD108')
    })
    it('should book to a post', async () => {
      const { manager } = await setupTests()
      const managerByUser2 = manager.connect(user2)

      const postMetadata = 'abi09nadu2brasfjl'
      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const fromTimestamp = now + 3600
      const toTimestamp = now + 7200
      const postId = await manager.nextPostId()

      const bitPrice = parseEth(1.5)
      const bidId = await manager.nextBidId()

      await manager.newPost(postMetadata, fromTimestamp, toTimestamp)
      expect(
        await managerByUser2.book(postId, {
          value: bitPrice,
        })
      )
        .to.emit(manager, 'Book')
        .withArgs(bidId, postId, user2.address, bitPrice)
      expect(await manager.bidderInfo(bidId)).to.deep.equal([
        bidId,
        postId,
        user2.address,
        bitPrice,
        '',
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
      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const fromTimestamp = now + 3600
      const toTimestamp = now + 7200
      const postId = await manager.nextPostId()
      await manager.newPost(postMetadata, fromTimestamp, toTimestamp)

      const bidMetadata2 = 'xxxdafakjkjfaj;jf'
      const bitPrice2 = parseEth(100)
      const bidId2 = await manager.nextBidId()
      await managerByUser2.bid(postId, bidMetadata2, {
        value: bitPrice2,
      })

      const bidMetadata3 = 'saedafakjkjfaj;jf'
      const bitPrice3 = parseEth(200)
      await managerByUser3.bid(postId, bidMetadata3, {
        value: bitPrice3,
      })

      const user1BalanceBeforeClose = await user1.getBalance()
      const user2BalanceBeforeClose = await user2.getBalance()

      expect(await manager.close(bidId2))
        .to.emit(manager, 'Close')
        .withArgs(bidId2, postId, user2.address, bitPrice2, bidMetadata2)
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
    })
  })

  describe('refund', async () => {
    it('should refund after the period', async () => {
      const { manager, right } = await setupTests()
      const managerByUser2 = manager.connect(user2)
      const managerByUser3 = manager.connect(user3)

      const postMetadata = 'abi09nadu2brasfjl'
      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const fromTimestamp = now + 3600
      const toTimestamp = now + 7200
      const postId = await manager.nextPostId()

      await manager.newPost(postMetadata, fromTimestamp, toTimestamp)

      const bidMetadata2 = 'xxxdafakjkjfaj;jf'
      const bitPrice2 = parseEth(100)
      const bidId2 = await manager.nextBidId()
      await managerByUser2.bid(postId, bidMetadata2, {
        value: bitPrice2,
      })

      const bidMetadata3 = 'saedafakjkjfaj;jf'
      const bitPrice3 = parseEth(200)
      const bidId3 = await manager.nextBidId()
      await managerByUser3.bid(postId, bidMetadata3, {
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

    it('cannot be refunded after the acceptation', async () => {
      const { manager, right } = await setupTests()
      const managerByUser2 = manager.connect(user2)
      const managerByUser3 = manager.connect(user3)

      const postMetadata = 'abi09nadu2brasfjl'
      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const fromTimestamp = now + 3600
      const toTimestamp = now + 7200
      const postId = await manager.nextPostId()

      await manager.newPost(postMetadata, fromTimestamp, toTimestamp)

      const bidMetadata2 = 'xxxdafakjkjfaj;jf'
      const bitPrice2 = parseEth(100)
      const bidId2 = await manager.nextBidId()
      await managerByUser2.bid(postId, bidMetadata2, {
        value: bitPrice2,
      })

      const bidMetadata3 = 'saedafakjkjfaj;jf'
      const bitPrice3 = parseEth(200)
      const bidId3 = await manager.nextBidId()
      await managerByUser3.bid(postId, bidMetadata3, {
        value: bitPrice3,
      })
      await manager.close(bidId2)

      await expect(managerByUser2.refund(bidId2)).to.be.revertedWith('AD107')
    })
  })

  describe('withdraw', async () => {
    it('should withdraw after the close', async () => {
      const { manager, vault } = await setupTests()
      const managerByUser2 = manager.connect(user2)
      const managerByUser3 = manager.connect(user3)

      const postMetadata = 'abi09nadu2brasfjl'
      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const fromTimestamp = now + 3600
      const toTimestamp = now + 7200
      const postId = await manager.nextPostId()
      await manager.newPost(postMetadata, fromTimestamp, toTimestamp)

      const bidMetadata2 = 'xxxdafakjkjfaj;jf'
      const bitPrice2 = parseEth(100)
      const bidId2 = await manager.nextBidId()
      await managerByUser2.bid(postId, bidMetadata2, {
        value: bitPrice2,
      })

      const bidMetadata3 = 'saedafakjkjfaj;jf'
      const bitPrice3 = parseEth(200)
      await managerByUser3.bid(postId, bidMetadata3, {
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
    it('should call a book', async () => {
      const { manager, right } = await setupTests()
      const managerByUser2 = manager.connect(user2)
      const managerByUser3 = manager.connect(user3)

      const postMetadata = 'abi09nadu2brasfjl'
      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const fromTimestamp = now + 3600
      const toTimestamp = now + 7200
      const postId = await manager.nextPostId()

      await manager.newPost(postMetadata, fromTimestamp, toTimestamp)
      const bitPrice2 = parseEth(100)
      const bidId2 = await manager.nextBidId()
      await managerByUser2.book(postId, {
        value: bitPrice2,
      })

      const bitPrice3 = parseEth(200)
      await managerByUser3.book(postId, {
        value: bitPrice3,
      })
      expect(await manager.call(bidId2))
        .to.emit(manager, 'Call')
        .withArgs(bidId2, postId, user2.address, bitPrice2)

      expect(await right.ownerOf(postId)).to.be.eq(user2.address)
      expect(await right.tokenURI(postId)).to.be.eq(`ipfs://${postMetadata}`)
    })
    it('cannot be done post already closed', async () => {
      const { manager, right } = await setupTests()
      const managerByUser2 = manager.connect(user2)
      const managerByUser3 = manager.connect(user3)

      const postMetadata = 'abi09nadu2brasfjl'
      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const fromTimestamp = now + 3600
      const toTimestamp = now + 7200
      const postId = await manager.nextPostId()

      await manager.newPost(postMetadata, fromTimestamp, toTimestamp)
      const bitPrice2 = parseEth(100)
      const bidId2 = await manager.nextBidId()
      await managerByUser2.book(postId, {
        value: bitPrice2,
      })
      const bidId3 = await manager.nextBidId()

      const bitPrice3 = parseEth(200)
      await managerByUser3.book(postId, {
        value: bitPrice3,
      })
      await manager.call(bidId2)
      await expect(manager.call(bidId3)).to.be.revertedWith('AD113')
    })
    it('cannot be done except by owners', async () => {
      const { manager } = await setupTests()
      const managerByUser2 = manager.connect(user2)
      const managerByUser3 = manager.connect(user3)

      const postMetadata = 'abi09nadu2brasfjl'
      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const fromTimestamp = now + 3600
      const toTimestamp = now + 7200
      const postId = await manager.nextPostId()

      await manager.newPost(postMetadata, fromTimestamp, toTimestamp)
      const bidMetadata2 = ''
      const bitPrice2 = parseEth(100)
      const bidId2 = await manager.nextBidId()
      await managerByUser2.bid(postId, bidMetadata2, {
        value: bitPrice2,
      })

      await expect(managerByUser3.call(bidId2)).to.be.revertedWith('AD102')
    })
    it('cannot be done the bid not exists', async () => {
      const { manager } = await setupTests()
      const managerByUser2 = manager.connect(user2)

      const postMetadata = 'abi09nadu2brasfjl'
      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const fromTimestamp = now + 3600
      const toTimestamp = now + 7200
      const postId = await manager.nextPostId()

      await manager.newPost(postMetadata, fromTimestamp, toTimestamp)
      const bidMetadata2 = ''
      const bitPrice2 = parseEth(100)
      await managerByUser2.bid(postId, bidMetadata2, {
        value: bitPrice2,
      })
      await expect(manager.call(999)).to.be.revertedWith('AD108')
    })
  })

  describe('propose', async () => {
    it('should propose on the book', async () => {
      const { manager, vault, pool } = await setupTests()
      const managerByUser2 = manager.connect(user2)
      const managerByUser3 = manager.connect(user3)

      const postMetadata = 'abi09nadu2brasfjl'
      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const fromTimestamp = now + 3600
      const toTimestamp = now + 7200
      const postId = await manager.nextPostId()

      await manager.newPost(postMetadata, fromTimestamp, toTimestamp)
      const bitPrice2 = parseEth(100)
      const bidId2 = await manager.nextBidId()
      await managerByUser2.book(postId, {
        value: bitPrice2,
      })

      const bidMetadata3 = 'saedafakjkjfaj;jf'
      const bitPrice3 = parseEth(200)
      await managerByUser3.bid(postId, bidMetadata3, {
        value: bitPrice3,
      })
      await manager.call(bidId2)

      const proposedMetadata = 'kjfkajlfjaji3j'
      expect(await managerByUser2.propose(postId, proposedMetadata))
        .to.emit(manager, 'Propose')
        .withArgs(bidId2, postId, proposedMetadata)
    })
  })

  describe('accept', async () => {
    it('should accept the proposal', async () => {
      const { manager, vault } = await setupTests()
      const managerByUser2 = manager.connect(user2)
      const managerByUser3 = manager.connect(user3)

      const postMetadata = 'abi09nadu2brasfjl'
      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const fromTimestamp = now + 3600
      const toTimestamp = now + 7200
      const postId = await manager.nextPostId()

      await manager.newPost(postMetadata, fromTimestamp, toTimestamp)
      const bitPrice2 = parseEth(100)
      const bidId2 = await manager.nextBidId()
      await managerByUser2.book(postId, {
        value: bitPrice2,
      })

      const bitPrice3 = parseEth(200)
      await managerByUser3.book(postId, {
        value: bitPrice3,
      })
      await manager.call(bidId2)

      const proposedMetadata = 'kjfkajlfjaji3j'
      await managerByUser2.propose(postId, proposedMetadata)

      expect(await manager.accept(postId))
        .to.emit(manager, 'Accept')
        .withArgs(postId, bidId2)
    })
    it('should burn the distribution right', async () => {
      const { manager, right } = await setupTests()
      const managerByUser2 = manager.connect(user2)

      const postMetadata = 'abi09nadu2brasfjl'
      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const fromTimestamp = now + 3600
      const toTimestamp = now + 7200
      const postId = await manager.nextPostId()

      await manager.newPost(postMetadata, fromTimestamp, toTimestamp)
      const bitPrice2 = parseEth(100)
      const bidId2 = await manager.nextBidId()
      await managerByUser2.book(postId, {
        value: bitPrice2,
      })

      await manager.call(bidId2)

      const proposedMetadata = 'kjfkajlfjaji3j'
      await managerByUser2.propose(postId, proposedMetadata)
      expect(await right.ownerOf(postId)).to.be.eq(user2.address)

      await manager.accept(postId)
      await expect(right.ownerOf(postId)).to.be.revertedWith(
        'ERC721: owner query for nonexistent token'
      )
    })
  })

  describe('displayMetadata', async () => {
    it('should display a valid metadata', async () => {
      const { manager, vault } = await setupTests()
      const managerByUser2 = manager.connect(user2)

      const postMetadata = 'abi09nadu2brasfjl'
      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const fromTimestamp = now - 3200
      const toTimestamp = now + 7200
      const postId = await manager.nextPostId()

      await manager.newPost(postMetadata, fromTimestamp, toTimestamp)
      const bitPrice2 = parseEth(100)
      const bidId2 = await manager.nextBidId()
      await managerByUser2.book(postId, {
        value: bitPrice2,
      })
      await manager.call(bidId2)
      const proposedMetadata = 'kjfkajlfjaji3j'
      await managerByUser2.propose(postId, proposedMetadata)
      await manager.accept(postId)
      expect(
        await managerByUser2.displayByMetadata(user1.address, postMetadata)
      ).to.be.eq(proposedMetadata)
    })
    it('should be reverted if there is no valid Post', async () => {
      const { manager, vault } = await setupTests()
      const managerByUser2 = manager.connect(user2)

      const postMetadata = 'abi09nadu2brasfjl'
      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const fromTimestamp = now - 3200
      const toTimestamp = now + 1600
      await manager.newPost(postMetadata, fromTimestamp, toTimestamp)
      await network.provider.send('evm_increaseTime', [3600])
      await network.provider.send('evm_mine')
      await expect(
        managerByUser2.displayByMetadata(user1.address, postMetadata)
      ).to.be.revertedWith('AD110')
    })
  })
})
