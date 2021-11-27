import { expect } from 'chai'
import { ethers } from 'ethers'
import { deployments, network, waffle } from 'hardhat'
import { getAdManagerABI } from '../scripts/common/file'
import {
  getAdManagerContract,
  getMediaFactoryContract,
  getMediaRegistryContract,
  getNameRegistryContract,
} from './utils/setup'

describe('MediaFactory', async () => {
  const [user1, user2, user3, user4, user5] = waffle.provider.getWallets()

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
    }
  })

  describe('newMedia', async () => {
    it('should new a account of media', async () => {
      const { now, factory, manager, name, registry } = await setupTests()

      const applicationMetadata = 'xxdsfjakjajijraksldfjak'
      const updatableMetadata = 'kykesrjisjklwjeidfhsjfa'
      const { proxy } = await newMediaWith(user2, factory, name, {
        applicationMetadata: applicationMetadata,
        updatableMetadata: updatableMetadata,
      })
      expect(proxy).is.not.null
      expect(await registry.allAccounts(proxy)).to.deep.equal([
        proxy,
        user2.address,
        applicationMetadata,
        updatableMetadata,
      ])
    })

    it('should revert because the sender is not the owner', async () => {
      const { factory, name } = await setupTests()

      const initializer = defaultInitializer(name.address)
      await expect(
        factory
          .connect(user2)
          .newMedia(
            user2.address,
            'dfajkajdjadafk',
            'kykesrjisjklwjeidfhsjfa',
            initializer,
            1
          )
      ).to.be.revertedWith('KD012')
    })
  })
})

export type NewMediaProps = {
  initializer?: string
  applicationMetadata?: string
  updatableMetadata?: string
  saltNonce?: number
}

export const newMediaWith = async (
  user: ethers.Wallet,
  factory: ethers.Contract,
  name: ethers.Contract,
  props?: NewMediaProps
) => {
  const initializer = defaultInitializer(name.address)
  const tx = await factory.newMedia(
    user.address,
    props?.applicationMetadata
      ? props?.applicationMetadata
      : 'abi09nadu2brasfjl',
    props?.updatableMetadata ? props?.updatableMetadata : '1eqe23kerfkamfka',
    props?.initializer ? props.initializer : initializer,
    props?.saltNonce ? props.saltNonce : 1
  )
  const rc = await tx.wait()
  const event = rc.events.find((event: any) => event.event === 'CreateProxy')
  return event.args
}

const defaultInitializer = (name: string) => {
  const ifaceAdManager = new ethers.utils.Interface(getAdManagerABI())
  const initializer = ifaceAdManager.encodeFunctionData('initialize', [
    'NameA',
    'https://base/',
    name,
  ])
  return initializer
}
