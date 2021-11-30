import fs from 'fs'
import path from 'path'

export const getMediaFactoryABI = () => {
  const compiled = JSON.parse(
    fs.readFileSync(getCompiledMediaFactoryPath()).toString()
  )
  return compiled.abi
}

export const getAdManagerABI = () => {
  const compiled = JSON.parse(
    fs.readFileSync(getCompiledAdManagerPath()).toString()
  )
  return compiled.abi
}

export const getMockTimeAdManagerABI = () => {
  const compiled = JSON.parse(
    fs.readFileSync(getCompiledMockTimeAdManagerPath()).toString()
  )
  return compiled.abi
}

// export const getVoucherABI = () => {
//   const compiled = JSON.parse(
//     fs.readFileSync(getCompiledVoucherPath()).toString()
//   )
//   return compiled.abi
// }

// export const getNameRegistryABI = () => {
//   const compiled = JSON.parse(
//     fs.readFileSync(getCompiledNameRegistryPath()).toString()
//   )
//   return compiled.abi
// }

export const getMediaFactoryAddress = (network: string) => {
  const json = JSON.parse(
    fs.readFileSync(getDeployedMediaFactoryPath(network)).toString()
  )
  return json.address
}

// export const getVoucherAddress = (network: string) => {
//   const json = JSON.parse(
//     fs.readFileSync(getDeployedVoucherPath(network)).toString()
//   )
//   return json.address
// }

export const getNameRegistryAddress = (network: string) => {
  const json = JSON.parse(
    fs.readFileSync(getNameRegistryPath(network)).toString()
  )
  return json.address
}

export const getCompiledMediaFactoryPath = () =>
  path.join(
    __dirname,
    '..',
    '..',
    'build',
    'artifacts',
    'contracts',
    'proxies',
    'MediaFactory.sol',
    'MediaFactory.json'
  )

export const getCompiledAdManagerPath = () =>
  path.join(
    __dirname,
    '..',
    '..',
    'build',
    'artifacts',
    'contracts',
    'AdManager.sol',
    'AdManager.json'
  )

export const getCompiledMockTimeAdManagerPath = () =>
  path.join(
    __dirname,
    '..',
    '..',
    'build',
    'artifacts',
    'contracts',
    'test',
    'MockTimeAdManager.sol',
    'MockTimeAdManager.json'
  )

// export const getCompiledVoucherPath = () =>
//   path.join(
//     __dirname,
//     '..',
//     '..',
//     'build',
//     'artifacts',
//     'contracts',
//     'token',
//     'Voucher.sol',
//     'Voucher.json'
//   )

// export const getCompiledNameRegistryPath = () =>
//   path.join(
//     __dirname,
//     '..',
//     '..',
//     'build',
//     'artifacts',
//     'contracts',
//     'accessors',
//     'NameRegistry.sol',
//     'NameRegistry.json'
//   )

export const getDeployedMediaFactoryPath = (network: string) =>
  path.join(__dirname, '..', '..', 'deployments', network, 'MediaFactory.json')

// export const getDeployedVoucherPath = (network: string) =>
//   path.join(__dirname, '..', '..', 'deployments', network, 'Voucher.json')

export const getNameRegistryPath = (network: string) =>
  path.join(__dirname, '..', '..', 'deployments', network, 'NameRegistry.json')
