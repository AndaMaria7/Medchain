require('dotenv').config()
const ethers = require('ethers')
const { Aquarius, ConfigHelper } = require('@oceanprotocol/lib')

// Environment variables
const PRIVATE_KEY = process.env.PRIVATE_KEY || '0xYOUR_PRIVATE_KEY_HERE'
const OCEAN_NETWORK_URL = process.env.OCEAN_NETWORK_URL || 'https://polygon-rpc.com'
const AQUARIUS_URL = process.env.AQUARIUS_URL || 'https://v4.aquarius.oceanprotocol.com'
const PROVIDER_URL = process.env.PROVIDER_URL || 'https://v4.provider.oceanprotocol.com'

// Validate required environment variables
if (!PRIVATE_KEY || PRIVATE_KEY === '0xYOUR_PRIVATE_KEY_HERE') {
  console.error('❌ PRIVATE_KEY not set in environment variables')
  process.exit(1)
}

async function createOceanConfig() {
  try {
    console.log('🌊 Initializing Ocean Protocol v4 configuration...')
    console.log('🌐 Network URL:', OCEAN_NETWORK_URL)
    console.log('🔍 Aquarius URL:', AQUARIUS_URL)
    console.log('⚙️ Provider URL:', PROVIDER_URL)
    
    // Create ethers provider and wallet
    const provider = new ethers.providers.JsonRpcProvider(OCEAN_NETWORK_URL)
    const publisherAccount = new ethers.Wallet(PRIVATE_KEY, provider)
    const consumerAccount = publisherAccount // For simplicity, using same account
    
    const address = await publisherAccount.getAddress()
    console.log('👤 Wallet address:', address)
    
    // Get network info
    const network = await provider.getNetwork()
    const chainId = network.chainId
    console.log('🔗 Chain ID:', chainId)
    
    // Get Ocean configuration for this chain
    const configHelper = new ConfigHelper()
    const config = configHelper.getConfig(chainId)
    
    if (!config) {
      throw new Error(`No configuration found for chain ID ${chainId}`)
    }
    
    // Override URLs if provided
    if (AQUARIUS_URL) {
      config.metadataCacheUri = AQUARIUS_URL
    }
    if (PROVIDER_URL) {
      config.providerUri = PROVIDER_URL
    }
    
    // Create Aquarius instance
    const aquarius = new Aquarius(config.metadataCacheUri)
    
    console.log('✅ Ocean Protocol v4 initialized successfully')
    
    return {
      config,
      aquarius,
      publisherAccount,
      consumerAccount,
      provider,
      chainId,
      address
    }
    
  } catch (error) {
    console.error('❌ Failed to initialize Ocean Protocol:', error.message)
    throw error
  }
}

// Export the configuration
let oceanConfig = null

async function getOceanConfig() {
  if (!oceanConfig) {
    oceanConfig = await createOceanConfig()
  }
  return oceanConfig
}

// For backward compatibility
module.exports = {
  getOceanConfig,
  oceanConfig: getOceanConfig(),
  // Legacy exports for existing code
  get config() { return getOceanConfig().then(c => c.config) },
  get aquarius() { return getOceanConfig().then(c => c.aquarius) },
  get wallet() { return getOceanConfig().then(c => c.publisherAccount) },
  get ocean() { return getOceanConfig().then(c => c) }
}