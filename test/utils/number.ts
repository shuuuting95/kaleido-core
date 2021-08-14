import { ethers, utils } from 'ethers'

export const token = (amount: number) => {
  return ethers.utils.parseUnits(String(amount), 18)
}

export const parseEth = (amount: number) => {
  return utils.parseEther(String(amount))
}
