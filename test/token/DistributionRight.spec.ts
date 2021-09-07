import { Contract } from '@ethersproject/contracts'
import { Wallet } from '@ethersproject/wallet'
import { expect } from 'chai'
import { deployments, network, waffle } from 'hardhat'
import { bookAs, postAs } from '../ad/AdManager.spec'
import { parseEth } from './../utils/number'
import {
  getAdManagerContract,
  getAdPoolContract,
  getDistributionRightContract,
  getVaultContract,
} from './../utils/setup'

describe('DistributionRight', async () => {
  const [postOwner, holder, newHolder] = waffle.provider.getWallets()

  const setupTests = deployments.createFixture(async ({ deployments }) => {
    await deployments.fixture()
    const now = Date.now()
    await network.provider.send('evm_setNextBlockTimestamp', [now])
    await network.provider.send('evm_mine')
    return {
      manager: await getAdManagerContract(),
      right: await getDistributionRightContract(),
      vault: await getVaultContract(),
      pool: await getAdPoolContract(),
    }
  })

  describe('transferFrom', async () => {
    it('can transfer the token without value', async () => {
      const { manager, right, vault } = await setupTests()
      const tokenId = await manager.nextPostId()
      await distributeRightTo(holder, manager)
      const ownerBalanceBefore = await postOwner.getBalance()
      const valutBalanceBefore = await vault.balance()

      const rightByHolder = right.connect(holder)
      await rightByHolder.transferFrom(
        holder.address,
        newHolder.address,
        tokenId
      )
      const ownerBalanceAfter = await postOwner.getBalance()
      const valutBalanceAfter = await vault.balance()
      expect(ownerBalanceAfter).to.be.equals(ownerBalanceBefore)
      expect(valutBalanceAfter).to.be.equals(valutBalanceBefore)
    })
    it('should distribute to owner and vault 3% of transaction value', async () => {
      const { manager, right, vault } = await setupTests()

      const tokenId = await manager.nextPostId()
      await distributeRightTo(holder, manager)
      const ownerBalanceBefore = await postOwner.getBalance()
      const valutBalanceBefore = await vault.balance()
      const newHolderBalanceBefore = await newHolder.getBalance()
      const rightByHolder = right.connect(holder)
      const price = parseEth(100)
      const distributed = parseEth(3)
      const distributedToNewHolder = parseEth(94)
      await rightByHolder.transferFrom(
        holder.address,
        newHolder.address,
        tokenId,
        { value: price }
      )
      const ownerBalanceAfter = await postOwner.getBalance()
      const valutBalanceAfter = await vault.balance()
      const newHolderBalanceAfter = await newHolder.getBalance()
      expect(ownerBalanceAfter.sub(ownerBalanceBefore)).to.be.equals(
        distributed
      )
      expect(valutBalanceAfter.sub(valutBalanceBefore)).to.be.equals(
        distributed
      )
      expect(newHolderBalanceAfter.sub(newHolderBalanceBefore)).to.be.equals(
        distributedToNewHolder
      )
    })
    it('should be reverted if sender is not an token owner', async () => {
      const { manager, right, vault } = await setupTests()

      const tokenId = await manager.nextPostId()
      await distributeRightTo(holder, manager)
      const ownerBalanceBefore = await postOwner.getBalance()
      const valutBalanceBefore = await vault.balance()
      const newHolderBalanceBefore = await newHolder.getBalance()
      const rightByHolder = right.connect(holder)
      const price = parseEth(100)
      await expect(
        rightByHolder.transferFrom(
          newHolder.address,
          postOwner.address,
          tokenId,
          { value: price }
        )
      ).to.be.revertedWith('ERC721: transfer of token that is not own')
      const ownerBalanceAfter = await postOwner.getBalance()
      const valutBalanceAfter = await vault.balance()
      const newHolderBalanceAfter = await newHolder.getBalance()
      expect(ownerBalanceAfter).to.be.equals(ownerBalanceBefore)
      expect(valutBalanceAfter).to.be.equals(valutBalanceBefore)
      expect(newHolderBalanceAfter).to.be.equals(newHolderBalanceBefore)
    })
  })

  describe('transferByAllowedContract', async () => {
    it('can transfer the token without value', async () => {
      const { manager, right, vault } = await setupTests()
      const tokenId = await manager.nextPostId()
      const bidId2 = await manager.nextBidId()
      await book(holder, manager)
      await expect(manager.call(bidId2)).to.emit(right, 'Transfer')
    })
  })
})

async function distributeRightTo(bidder: Wallet, manager: Contract) {
  const bidId2 = await manager.nextBidId()
  await book(bidder, manager)
  await manager.call(bidId2)
}

async function book(bidder: Wallet, manager: Contract) {
  const postId = await manager.nextPostId()
  await postAs(manager, {
    postMetadata: '',
  })
  const managerByBidder = manager.connect(bidder)

  await bookAs(managerByBidder, postId)
}
