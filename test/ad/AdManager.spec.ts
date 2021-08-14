import { expect } from 'chai'
import { BigNumber } from 'ethers'
import { deployments, network, waffle } from 'hardhat'
import { ADDRESS_ZERO } from '../utils/address'
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

      const metadata = 'abi09nadu2brasfjl'
      const initialPrice = 10
      const periodHours = 60 * 60 * 24 * 3 // 72 hours

      const now = Date.now()
      await network.provider.send('evm_setNextBlockTimestamp', [now])
      await network.provider.send('evm_mine')
      const postId = await manager.computePostId(
        metadata,
        (await waffle.provider.getBlockNumber()) + 1
      )

      expect(await manager.newPost(metadata, initialPrice, periodHours))
        .to.emit(manager, 'NewPost')
        .withArgs(
          postId,
          user1.address,
          metadata,
          initialPrice,
          periodHours,
          now + 1,
          now + 1 + periodHours
        )
      expect(await manager.allPosts(postId)).to.deep.equal([
        postId,
        user1.address,
        metadata,
        BigNumber.from(initialPrice),
        BigNumber.from(periodHours),
        BigNumber.from(now + 1),
        BigNumber.from(now + 1 + periodHours),
        ADDRESS_ZERO,
      ])
    })
  })
})
