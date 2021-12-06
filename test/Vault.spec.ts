import { parseEther } from '@ethersproject/units'
import { expect } from 'chai'
import { ethers } from 'ethers'
import { deployments, network, waffle } from 'hardhat'
import { getMediaFacadeABI } from '../scripts/common/file'
import { option } from '../scripts/common/wallet'
import { newMediaWith } from './MediaFactory.spec'
import {
  getMediaFacadeContract,
  getMediaFactoryContract,
  getMediaRegistryContract,
  getNameRegistryContract,
  getVaultContract,
} from './utils/setup'

describe('Vault', async () => {
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
    }
  })
  const _manager = (proxy: string) =>
    new ethers.Contract(proxy, getMediaFacadeABI(), user1)

  describe('withdraw', async () => {
    it('should withdraw fees', async () => {
      const { factory, name, vault } = await setupTests()
      const { proxy } = await newMediaWith(user4, factory, name)
      const manager = _manager(proxy)

      await user3.sendTransaction({
        to: manager.address,
        value: parseEther('12'),
      })
      expect(await vault.balance()).to.be.eq(parseEther('6'))

      const user1BeforeBalance = await user1.getBalance()
      const withdrawalAmount = parseEther('4')
      expect(await vault.withdraw(withdrawalAmount, option()))
        .to.emit(vault, 'Withdraw')
        .withArgs(user1.address, withdrawalAmount)
      expect(await vault.balance()).to.be.eq(parseEther('2'))
      const user1AfterBalance = await user1.getBalance()
      expect(user1AfterBalance.sub(user1BeforeBalance)).to.be.gt(
        parseEther('3.9')
      )
      expect(user1AfterBalance.sub(user1BeforeBalance)).to.be.lt(
        parseEther('4.0')
      )
    })

    it('should revert because the amount exceeds the deposited amount', async () => {
      const { factory, name, vault } = await setupTests()
      const { proxy } = await newMediaWith(user4, factory, name)
      const manager = _manager(proxy)

      await user3.sendTransaction({
        to: manager.address,
        value: parseEther('12'),
      })
      expect(await vault.balance()).to.be.eq(parseEther('6'))

      const withdrawalAmount = parseEther('6.1')
      await expect(
        vault.withdraw(withdrawalAmount, option())
      ).to.be.revertedWith('KD140')
    })

    it('should revert because the caller is not the owner', async () => {
      const { factory, name, vault } = await setupTests()
      const { proxy } = await newMediaWith(user4, factory, name)
      const manager = _manager(proxy)

      await user3.sendTransaction({
        to: manager.address,
        value: parseEther('12'),
      })

      const withdrawalAmount = parseEther('6.1')
      await expect(
        vault.connect(user2).withdraw(withdrawalAmount, option())
      ).to.be.revertedWith('Ownable: caller is not the owner')
    })
  })
})
