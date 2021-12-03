import { expect } from 'chai'
import { utils } from 'ethers'
import { deployments, ethers, network, waffle } from 'hardhat'
import {
  getAdManagerV2ABI,
  getMockTimeAdManagerABI,
} from '../scripts/common/file'
import { option } from '../scripts/common/wallet'
import { newMediaWith } from './MediaFactory.spec'
import {
  getMediaFactoryContract,
  getMediaRegistryContract,
  getNameRegistryContract,
  getVaultContract,
} from './utils/setup'

describe('Upgradeable AdManager', async () => {
  const [user1, user2, user3, user4] = waffle.provider.getWallets()

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
      vault: await getVaultContract(),
    }
  })
  const _manager = (proxy: string) =>
    new ethers.Contract(proxy, getMockTimeAdManagerABI(), user1)

  describe('AdManager V2', async () => {
    it('should update newSpace', async () => {
      const { factory, name, vault } = await setupTests()
      const { proxy } = await newMediaWith(user2, factory, name)
      const manager = _manager(proxy)

      const spaceMetadata = '43ijtejafjal;j32iajef;dlkajd'
      const spaceMetadata2 = '4tirejsjrkwj4twijgej;sfklajdkajkfj'
      await manager.connect(user2).newSpace(spaceMetadata, option())
      expect(await manager.spaced(spaceMetadata)).to.be.true
      expect(await manager.spaced(spaceMetadata2)).to.be.false

      const AdManagerV2 = await ethers.getContractFactory('AdManagerV2', {
        libraries: {
          Ad: (await deployments.get('Ad')).address,
        },
      })
      const v2 = await AdManagerV2.deploy()
      await name.set(
        utils.solidityKeccak256(['string'], ['AdManager']),
        v2.address
      )
      const managerV2 = new ethers.Contract(proxy, getAdManagerV2ABI(), user1)
      expect(await managerV2.spaced(spaceMetadata)).to.be.true

      const spaceMetadata3 = 't34ijri3wjrfkjdsfasjf;l'
      await managerV2.connect(user2).newSpace(spaceMetadata3, option())
      expect(await managerV2.spaced(spaceMetadata3)).to.be.true
      expect(await managerV2.getAdditional()).to.be.eq('additional state')
    })
  })
})
