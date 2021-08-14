import { ethers } from 'ethers'

export const token = (amount: number) => {
  return ethers.utils.parseUnits(String(amount), 18)
}
