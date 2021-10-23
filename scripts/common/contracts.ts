import { ethers } from 'ethers'
import { getMediaFactoryABI } from './file'

export const getMediaFactoryInstance = (
  address: string,
  wallet: ethers.Wallet
) => {
  const abi = getMediaFactoryABI()
  const contract = new ethers.Contract(address, abi, wallet)
  return contract
}
