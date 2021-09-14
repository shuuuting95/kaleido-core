import '@nomiclabs/hardhat-waffle'
import 'hardhat-abi-exporter'
import 'hardhat-deploy'
import 'hardhat-deploy-ethers'
import 'hardhat-gas-reporter'
import { HardhatUserConfig } from 'hardhat/types/config'
import './src/tasks/deploy_contracts'
// eslint-disable-next-line @typescript-eslint/no-var-requires
require('dotenv').config()

const INFURA_KEY = process.env.INFURA_KEY || ''
const PRIVATE_KEY = process.env.PRIVATE_KEY || ''
const POLYGON_RPC_URL = process.env.POLYGON_RPC
const gasPrice = 20000000000 // 2 gwei
const COINMARKETCAP = process.env.COINMARKETCAP || ''

const config: HardhatUserConfig = {
  defaultNetwork: 'hardhat',
  paths: {
    artifacts: 'build/artifacts',
    cache: 'build/cache',
    deploy: 'src/deploy',
    sources: 'contracts',
  },
  solidity: {
    compilers: [
      {
        version: '0.8.6',
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000,
          },
        },
      },
    ],
  },
  namedAccounts: {
    deployer: 0,
  },
  networks: {
    hardhat: {
      throwOnTransactionFailures: true,
      throwOnCallFailures: true,
      allowUnlimitedContractSize: true,
      mining: {
        auto: true,
        interval: 0,
      },
      gasPrice: gasPrice,
    },
    ganache: {
      url: 'http://0.0.0.0:8545',
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${INFURA_KEY}`,
      accounts: [`0x${PRIVATE_KEY}`],
      gasPrice,
    },
    polygon: {
      chainId: 137,
      url: `${POLYGON_RPC_URL}`,
      accounts: [`0x${PRIVATE_KEY}`],
      gasPrice,
    },
  },
  gasReporter: {
    enabled: true,
    currency: 'JPY',
    gasPrice: 20,
    coinmarketcap: COINMARKETCAP,
  },
}
export default config
