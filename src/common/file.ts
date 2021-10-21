import fs from 'fs'
import path from 'path'

export const writeJsonToFile = (_path: string, json: any): void => {
  fs.writeFileSync(_path, JSON.stringify(json, null, '    '))
}

export const deployedAddessesPath = (network: string): string =>
  path.join(__dirname, '..', '..', 'integration', `${network}.json`)

export const deployedAddresses = (network: string) => {
  const content = JSON.parse(
    fs.readFileSync(deployedAddessesPath(network)).toString()
  )
  return content
}
