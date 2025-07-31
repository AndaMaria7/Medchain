const { getOceanConfig } = require('./config')
const { ProviderInstance, ZERO_ADDRESS } = require('@oceanprotocol/lib')
const fs = require('fs')

async function startEmergencyMatching(emergencyData) {
  try {
    console.log('🚨 Starting emergency matching compute job...')
    
    // Load hospital and algorithm assets
    const hospitalAssets = JSON.parse(fs.readFileSync('hospital_assets.json', 'utf8'))
    const algorithmAsset = JSON.parse(fs.readFileSync('algorithm_asset.json', 'utf8'))
    
    // Get first hospital dataset for demo (in production, would use all)
    const datasetDid = hospitalAssets[0].did
    const algorithmDid = algorithmAsset.did
    
    console.log('📊 Dataset DID:', datasetDid)
    console.log('🤖 Algorithm DID:', algorithmDid)
    
    const result = await startComputeJob(datasetDid, algorithmDid, emergencyData)
    
    return {
      jobId: result.jobId,
      result: result,
      emergencyData: emergencyData
    }
    
  } catch (error) {
    console.error('❌ Error starting compute job:', error.message)
    throw error
  }
}

// Updated v4 compute job implementation
async function startComputeJob(datasetDid, algorithmDid, additionalData = null) {
  try {
    console.log('⏳ Starting v4 compute job...')
    
    const oceanConfig = await getOceanConfig()
    const { aquarius, consumerAccount, config } = oceanConfig
    
    const consumer = await consumerAccount.getAddress()
    console.log('👤 Consumer address:', consumer)
    
    // Resolve assets using Aquarius
    const resolvedDatasetDdo = await aquarius.resolve(datasetDid)
    const resolvedAlgorithmDdo = await aquarius.resolve(algorithmDid)
    
    if (!resolvedDatasetDdo || !resolvedAlgorithmDdo) {
      throw new Error('Could not resolve dataset or algorithm from Aquarius')
    }
    
    console.log('✅ Assets resolved successfully')
    
    // Find compute service in dataset
    const computeService = resolvedDatasetDdo.services?.find(service => service.type === 'compute')
    if (!computeService) {
      throw new Error('No compute service found for dataset')
    }
    
    console.log('🔧 Found compute service:', computeService.id)
    
    // Get compute environments 
    const mytime = new Date()
    const providerInstance = new ProviderInstance(config.providerUri)
    const computeEnvs = await providerInstance.getComputeEnvironments()
    
    if (!computeEnvs || computeEnvs.length === 0) {
      throw new Error('No compute environments available')
    }
    
    // Choose the first available compute environment
    const computeEnv = computeEnvs[0]
    console.log('🖥️ Using compute environment:', computeEnv.id)
    
    // Create algorithm metadata
    const algorithmMeta = {
      language: 'python',
      format: 'docker-image',
      version: '1.0',
      container: {
        entrypoint: 'python algorithm.py',
        image: 'oceanprotocol/algo_dockers',
        tag: 'python-sql'
      }
    }
    
    // Add emergency data if provided
    const algorithmDataToken = resolvedAlgorithmDdo.services[0].datatokenAddress
    
    // Prepare compute job
    const assets = [
      {
        documentId: datasetDid,
        serviceId: computeService.id
      }
    ]
    
    const algorithm = {
      documentId: algorithmDid,
      serviceId: resolvedAlgorithmDdo.services[0].id,
      dataToken: algorithmDataToken,
      meta: algorithmMeta
    }
    
    // Add additional data as algorithm input if provided
    if (additionalData) {
      algorithm.meta.additionalInputs = [{
        input: JSON.stringify(additionalData)
      }]
    }
    
    console.log('📋 Starting compute job...')
    
    // Start compute job
    const computeResult = await providerInstance.startComputeJob(
      consumer,
      assets,
      algorithm,
      computeEnv.id,
      mytime.getTime() / 1000
    )
    
    if (!computeResult || !computeResult.jobId) {
      throw new Error('Failed to start compute job - no job ID returned')
    }
    
    console.log('✅ Compute job started!')
    console.log('🆔 Job ID:', computeResult.jobId)
    
    // Poll for results
    const result = await pollForResults(computeResult.jobId)
    
    return {
      jobId: computeResult.jobId,
      ...result
    }
    
  } catch (error) {
    console.error('❌ Error in startComputeJob:', error.message)
    throw error
  }
}

async function pollForResults(jobId, maxAttempts = 20) {
  console.log('⏳ Polling for compute results...')
  
  const oceanConfig = await getOceanConfig()
  const { config, consumerAccount } = oceanConfig
  const consumer = await consumerAccount.getAddress()
  
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      const providerInstance = new ProviderInstance(config.providerUri)
      
      // Get job status
      const jobStatus = await providerInstance.getComputeStatus(
        config.providerUri,
        consumer,
        jobId
      )
      
      console.log(`📊 Attempt ${attempt}: Job status = ${jobStatus?.status}`)
      
      if (jobStatus?.status === 'Completed') {
        console.log('✅ Compute job completed!')
        
        // Get results
        const jobResults = await providerInstance.getComputeResult(
          config.providerUri,
          consumer,
          jobId,
          0 // result index
        )
        
        return {
          status: 'completed',
          results: jobResults,
          jobDetails: jobStatus
        }
        
      } else if (jobStatus?.status === 'Failed' || jobStatus?.status === 'Error') {
        throw new Error(`Compute job failed: ${jobStatus?.statusText || 'Unknown error'}`)
      }
      
      // Wait 10 seconds before next poll
      await new Promise(resolve => setTimeout(resolve, 10000))
      
    } catch (error) {
      console.error(`❌ Error polling attempt ${attempt}:`, error.message)
      
      if (attempt === maxAttempts) {
        throw error
      }
    }
  }
  
  throw new Error('Compute job timed out after maximum attempts')
}

async function testEmergencyFlow() {
  // Sample emergency data
  const sampleEmergency = {
    emergencyId: 'emergency_' + Date.now(),
    location: { lat: 44.4200, lng: 26.1000 }, // Cluj-Napoca coordinates
    severity: 7, // High severity
    timestamp: new Date().toISOString(),
    type: 'cardiac',
    patient: {
      age: 45,
      gender: 'male',
      bloodType: 'O+',
      symptoms: ['chest pain', 'shortness of breath'],
      vitals: {
        heartRate: 110,
        bloodPressure: '140/90'
      }
    }
  }
  
  console.log('🧪 Testing emergency matching flow with Ocean.js v4...')
  console.log('🚨 Emergency data:', JSON.stringify(sampleEmergency, null, 2))
  
  try {
    const result = await startEmergencyMatching(sampleEmergency)
    
    console.log('🎉 Emergency matching completed!')
    console.log('📊 Result:', JSON.stringify(result, null, 2))
    
    return result
    
  } catch (error) {
    console.error('❌ Test failed:', error)
    throw error
  }
}

module.exports = {
  startEmergencyMatching,
  pollForResults,
  startComputeJob,
  testEmergencyFlow
}

if (require.main === module) {
  testEmergencyFlow()
    .then(() => console.log('🎉 Test completed!'))
    .catch(error => console.error('❌ Test error:', error))
}