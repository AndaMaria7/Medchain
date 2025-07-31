const { config, wallet, oceanNode } = require('./config')
const { ethers } = require('ethers')
const fs = require('fs')

// Sample hospital data for Romania
const hospitalData = [
  {
    name: "Spitalul Universitar de Urgență București",
    location: "București, Sector 5",
    data: {
      hospital_id: "spital_urgenta_bucuresti",
      icu_beds_available: 5,
      emergency_beds_available: 12,
      ventilators_available: 3,
      has_cardiac_surgery: true,
      has_trauma_center: true,
      average_wait_time_minutes: 25,
      location: { lat: 44.4268, lng: 26.1025 },
      last_updated: new Date().toISOString()
    }
  },
  {
    name: "Spitalul Județean Cluj",
    location: "Cluj-Napoca, Cluj", 
    data: {
      hospital_id: "spital_judetean_cluj",
      icu_beds_available: 8,
      emergency_beds_available: 15,
      ventilators_available: 5,
      has_cardiac_surgery: true,
      has_trauma_center: true,
      average_wait_time_minutes: 18,
      location: { lat: 46.7712, lng: 23.6236 },
      last_updated: new Date().toISOString()
    }
  },
  {
    name: "Spitalul Regina Maria București", 
    location: "București, Sector 1",
    data: {
      hospital_id: "regina_maria_bucuresti",
      icu_beds_available: 3,
      emergency_beds_available: 8,
      ventilators_available: 2,
      has_cardiac_surgery: true,
      has_trauma_center: false,
      average_wait_time_minutes: 15,
      location: { lat: 44.4378, lng: 26.0875 },
      last_updated: new Date().toISOString()
    }
  }
]

async function publishHospitalDataset(hospitalInfo) {
  try {
    console.log(`🏥 Publishing dataset for ${hospitalInfo.name}...`)
    
    // Create asset metadata for Ocean Node
    const metadata = {
      "@context": ["https://w3id.org/did/v1"],
      id: "", // Will be generated
      version: "4.1.0",
      chainId: config.chainId,
      nftAddress: "", // Will be set after NFT creation
      metadata: {
        created: new Date().toISOString(),
        updated: new Date().toISOString(),
        type: "dataset",
        name: `${hospitalInfo.name} - Emergency Capacity Data`,
        description: `Real-time emergency bed capacity and resources for ${hospitalInfo.name}`,
        author: wallet.address,
        license: "Private",
        tags: ["hospital", "emergency", "capacity", "romania", "healthcare"],
        additionalInformation: {
          hospital_name: hospitalInfo.name,
          location: hospitalInfo.location,
          data_type: "emergency_capacity",
          update_frequency: "hourly",
          categories: ["healthcare"],
          termsAndConditions: true
        }
      },
      services: [
        {
          id: "compute",
          type: "compute",
          files: [
            {
              type: "url",
              url: `data:application/json;base64,${Buffer.from(JSON.stringify(hospitalInfo.data)).toString('base64')}`,
              method: "GET"
            }
          ],
          datatokenAddress: "", // Will be set after datatoken creation
          serviceEndpoint: config.computeEndpoint,
          timeout: 3600,
          compute: {
            allowRawAlgorithm: false,
            allowNetworkAccess: false,
            publisherTrustedAlgorithms: [],
            publisherTrustedAlgorithmPublishers: []
          }
        }
      ]
    }
    
    console.log('📊 Created metadata structure')
    console.log('💾 Sample data size:', JSON.stringify(hospitalInfo.data).length, 'bytes')
    
    // For now, save the metadata locally (Ocean Node publishing requires more setup)
    const assetInfo = {
      hospital_name: hospitalInfo.name,
      hospital_location: hospitalInfo.location,
      metadata: metadata,
      sample_data: hospitalInfo.data,
      created_at: new Date().toISOString(),
      status: 'prepared' // Not yet published to Ocean Node
    }
    
    console.log(`✅ Hospital asset prepared: ${hospitalInfo.name}`)
    console.log(`📍 Hospital: ${hospitalInfo.name}`)
    console.log(`📍 Location: ${hospitalInfo.location}`)
    console.log(`💾 Data prepared for Ocean Node publishing`)
    console.log('='*60)
    
    return assetInfo
    
  } catch (error) {
    console.error(`❌ Error preparing ${hospitalInfo.name}:`, error.message)
    throw error
  }
}

async function prepareAllHospitals() {
  console.log('🚀 Preparing hospital datasets for Ocean Node...')
  console.log('📋 This will create the data structure needed for Ocean Protocol')
  
  const preparedAssets = []
  
  for (const hospital of hospitalData) {
    try {
      const asset = await publishHospitalDataset(hospital)
      preparedAssets.push(asset)
    } catch (error) {
      console.error(`Failed to prepare ${hospital.name}:`, error)
    }
  }
  
  // Save prepared assets
  fs.writeFileSync('hospital_assets.json', JSON.stringify(preparedAssets, null, 2))
  console.log(`💾 Prepared ${preparedAssets.length} hospital assets`)
  console.log(`📋 Asset details saved to hospital_assets.json`)
  console.log(`\n🎯 Next step: Create the AI matching algorithm`)
  
  return preparedAssets
}

// Export functions
module.exports = {
  publishHospitalDataset,
  prepareAllHospitals,
  hospitalData
}

// Run if executed directly
if (require.main === module) {
  prepareAllHospitals()
    .then(() => console.log('🎉 All hospital assets prepared!'))
    .catch(error => console.error('❌ Error:', error))
}