type MediaTokenMetadata = {
  name?: string
  image: string
  descrption: string
  external_url: string
}

export const NEW_MEDIA_TOKEN_INPUT: MediaTokenMetadata = {
  external_url: 'https://kaleidodao.org',
  descrption:
    'This is an NFT granted to EOAs who have registered with Kaleido as media.',
  image: 'ipfs://QmQrAe5Lt13D1Cx1R9d9bF1uqrhxx8CqjC4VKLMbJ4k9PQ',
}
