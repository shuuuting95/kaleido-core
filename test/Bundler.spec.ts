// import { expect } from 'chai'
// import { ethers } from 'ethers'
// import { deployments, network, waffle } from 'hardhat'
// import { getMediaFacadeABI } from '../scripts/common/file'
// import { buyWith, newPeriodWith } from './MediaFacade.spec'
// import { newMediaWith } from './MediaFactory.spec'
// import {
//   getMediaFacadeContract,
//   getBundlerContract,
//   getMediaFactoryContract,
//   getMediaRegistryContract,
//   getNameRegistryContract,
//   getVaultContract,
// } from './utils/setup'

describe('Bundler', async () => {
  //   const [user1, user2, user3, user4] = waffle.provider.getWallets()
  //   const setupTests = deployments.createFixture(async ({ deployments }) => {
  //     await deployments.fixture()
  //     const now = Date.now()
  //     await network.provider.send('evm_setNextBlockTimestamp', [now])
  //     await network.provider.send('evm_mine')
  //     return {
  //       now: now,
  //       factory: await getMediaFactoryContract(),
  //       manager: await getMediaFacadeContract(),
  //       name: await getNameRegistryContract(),
  //       registry: await getMediaRegistryContract(),
  //       vault: await getVaultContract(),
  //       bundler: await getBundlerContract(),
  //     }
  //   })
  //   const _manager = (proxy: string) =>
  //     new ethers.Contract(proxy, getMediaFacadeABI(), user1)
  //   describe('bundleToken', async () => {
  //     it('should bundle', async () => {
  //       const { now, factory, name, vault, bundler } = await setupTests()
  //       const { proxy } = await newMediaWith(user2, factory, name)
  //       const manager = _manager(proxy)
  //       const spaceMetadata = 'asfafkjksjfkajf'
  //       const displayStartTimestamp = now + 3600
  //       const displayEndTimestamp = now + 7200
  //       const tokenId1 = await manager.adId(
  //         spaceMetadata,
  //         displayStartTimestamp,
  //         displayEndTimestamp
  //       )
  //       await newPeriodWith(manager.connect(user2), {
  //         spaceMetadata: spaceMetadata,
  //         displayStartTimestamp: displayStartTimestamp,
  //         displayEndTimestamp: displayEndTimestamp,
  //       })
  //       await buyWith(manager.connect(user3), {
  //         tokenId: tokenId1,
  //       })
  //       const tokenId2 = await manager.adId(
  //         spaceMetadata,
  //         displayStartTimestamp + 5000,
  //         displayEndTimestamp + 5000
  //       )
  //       await newPeriodWith(manager.connect(user2), {
  //         spaceMetadata: spaceMetadata,
  //         displayStartTimestamp: displayStartTimestamp + 5000,
  //         displayEndTimestamp: displayEndTimestamp + 5000,
  //       })
  //       await buyWith(manager.connect(user3), {
  //         tokenId: tokenId2,
  //       })
  //       const tokenId3 = await manager.adId(
  //         spaceMetadata,
  //         displayStartTimestamp + 10000,
  //         displayEndTimestamp + 10000
  //       )
  //       await newPeriodWith(manager.connect(user2), {
  //         spaceMetadata: spaceMetadata,
  //         displayStartTimestamp: displayStartTimestamp + 10000,
  //         displayEndTimestamp: displayEndTimestamp + 10000,
  //       })
  //       await buyWith(manager.connect(user3), {
  //         tokenId: tokenId3,
  //       })
  //       const concatenated = bundleTokenIds([tokenId1, tokenId2, tokenId3])
  //       const bundleMetadata = 'sajjjrqijalkwejwjkjakdfe'
  //       expect(
  //         await bundler.connect(user3).bundleTokens(concatenated, bundleMetadata)
  //       )
  //         .to.emit(bundler, 'BundleTokens')
  //         .withArgs(10000001, concatenated, bundleMetadata)
  //     })
  //   })
})

// const bundleTokenIds = (tokenIds: ethers.BigNumber[]) =>
//   tokenIds.map((t) => zeroPaddedTokenId(t)).join('')

// const zeroPaddedTokenId = (tokenId: ethers.BigNumber) => {
//   let tokenStr = tokenId.toString()
//   while (tokenStr.length < 32) {
//     tokenStr = '0' + tokenStr
//   }
//   return tokenStr
// }
