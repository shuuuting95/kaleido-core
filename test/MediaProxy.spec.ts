import { parseEther } from '@ethersproject/units'
import { expect } from 'chai'
import { ethers } from 'ethers'
import { deployments, network, waffle } from 'hardhat'
import { getMediaFacadeABI } from '../scripts/common/file'
import { newMediaWith } from './MediaFactory.spec'
import {
  getEventEmitterContract,
  getMediaFacadeContract,
  getMediaFactoryContract,
  getMediaRegistryContract,
  getNameRegistryContract,
  getVaultContract,
} from './utils/setup'

describe('MediaProxy', async () => {
  const [user1, user2, user3, user4] = waffle.provider.getWallets()

  const setupTests = deployments.createFixture(async ({ deployments }) => {
    await deployments.fixture()
    const now = Date.now()
    await network.provider.send('evm_setNextBlockTimestamp', [now])
    await network.provider.send('evm_mine')
    return {
      now: now,
      factory: await getMediaFactoryContract(),
      manager: await getMediaFacadeContract(),
      name: await getNameRegistryContract(),
      registry: await getMediaRegistryContract(),
      vault: await getVaultContract(),
      event: await getEventEmitterContract(),
    }
  })
  const _manager = (proxy: string) =>
    new ethers.Contract(proxy, getMediaFacadeABI(), user1)

  describe('fallback', async () => {
    it('should transfer ETH to a proxy', async () => {
      const { factory, name, vault, event } = await setupTests()
      const { proxy } = await newMediaWith(user4, factory, name)
      const manager = _manager(proxy)

      expect(await manager.balance()).to.be.eq(0)
      expect(await vault.balance()).to.be.eq(0)
      await user3.sendTransaction({
        to: manager.address,
        value: parseEther('12'),
      })
      expect(await manager.balance()).to.be.eq(parseEther('6'))
      expect(await vault.balance()).to.be.eq(parseEther('6'))
    })
  })
})
