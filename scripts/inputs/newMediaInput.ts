type MediaTokenMetadata = {
  name?: string
  image: string
  description: string
  external_url: string
}

export const NEW_MEDIA_TOKEN_INPUT: MediaTokenMetadata = {
  external_url: 'https://kaleidodao.org',
  description: 'This NFT is granted to those who register as media in Kaleido.',
  image: 'ipfs://QmQrAe5Lt13D1Cx1R9d9bF1uqrhxx8CqjC4VKLMbJ4k9PQ',
}
