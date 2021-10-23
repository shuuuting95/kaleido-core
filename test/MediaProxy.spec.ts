import { parseEther } from '@ethersproject/units'
import { expect } from 'chai'
import { ethers } from 'ethers'
import { deployments, network, waffle } from 'hardhat'
import { getAdManagerABI } from '../scripts/common/file'
import { newMediaWith } from './MediaFactory.spec'
import {
  getAdManagerContract,
  getMediaFactoryContract,
  getMediaRegistryContract,
  getNameRegistryContract,
  getVaultContract,
} from './utils/setup'

describe('MediaProxy', async () => {
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
      vault: await getVaultContract(),
    }
  })
  const _manager = (proxy: string) =>
    new ethers.Contract(proxy, getAdManagerABI(), user1)

  describe('newSpace', async () => {
    it('should transfer ETH to a proxy', async () => {
      const { factory, name, vault } = await setupTests()
      const { proxy } = await newMediaWith(factory, name)
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
