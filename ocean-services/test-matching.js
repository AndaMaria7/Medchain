const { hospitalData } = require('./publisher')
const fs = require('fs')
const { spawn } = require('child_process')

// Test emergency matching locally
async function testEmergencyMatching() {
  console.log('🧪 Testing emergency matching algorithm locally...')
  
  // Load algorithm from file
  const algorithmAsset = JSON.parse(fs.readFileSync('algorithm_asset.json', 'utf8'))
  const algorithmCode = algorithmAsset.algorithm_code
  
  // Sample emergency in Bucharest
  const sampleEmergency = {
    emergencyId: 'emergency_' + Date.now(),
    location: { lat: 44.4200, lng: 26.1000 }, // Near Bucharest center
    severity: 7, // High severity (1-10 scale)
    timestamp: new Date().toISOString(),
    type: 'cardiac'
  }
  
  console.log('🚨 Test Emergency:')
  console.log('📍 Location: Bucharest Center (44.42, 26.10)')
  console.log('⚡ Severity: 7/10 (High)')
  console.log('💓 Type: Cardiac')
  
  // Extract just the hospital data
  const hospitalsForAlgorithm = hospitalData.map(h => h.data)
  
  console.log('\n🏥 Available Hospitals:')
  hospitalsForAlgorithm.forEach(hospital => {
    console.log(`   ${hospital.hospital_id}: ${hospital.icu_beds_available} ICU, ${hospital.emergency_beds_available} ER beds`)
  })
  
  try {
    // Create temporary Python script
    const pythonScript = algorithmCode.replace('if __name__ == "__main__":', 'if True:')
    fs.writeFileSync('temp_algorithm.py', pythonScript)
    
    // Run the algorithm
    const result = await runPythonAlgorithm(
      JSON.stringify(hospitalsForAlgorithm),
      JSON.stringify(sampleEmergency)
    )
    
    console.log('\n🎯 MATCHING RESULT:')
    console.log('='.repeat(50))
    console.log(`🏆 Best Match: ${result.matched_hospital_id}`)
    console.log(`📊 Match Score: ${result.match_score}/100`)
    console.log(`📏 Distance: ${result.distance_km.toFixed(1)} km`)
    console.log(`💡 Reasoning: ${result.reasoning}`)
    
    console.log('\n📋 All Hospital Scores:')
    result.all_hospitals.forEach(hospital => {
      console.log(`   ${hospital.hospital_id}: ${hospital.score} points (${hospital.distance_km.toFixed(1)}km)`)
      console.log(`      ${hospital.reasoning}`)
    })
    
    // Clean up
    fs.unlinkSync('temp_algorithm.py')
    
    console.log('\n✅ Algorithm test completed successfully!')
    console.log('🎯 Next step: Get test ETH to deploy to Ocean Protocol')
    
    return result
    
  } catch (error) {
    console.error('❌ Algorithm test failed:', error.message)
    // Clean up on error
    if (fs.existsSync('temp_algorithm.py')) {
      fs.unlinkSync('temp_algorithm.py')
    }
    throw error
  }
}

function runPythonAlgorithm(hospitalsJson, emergencyJson) {
  return new Promise((resolve, reject) => {
    const python = spawn('python3', ['temp_algorithm.py', hospitalsJson, emergencyJson])
    
    let output = ''
    let error = ''
    
    python.stdout.on('data', (data) => {
      output += data.toString()
    })
    
    python.stderr.on('data', (data) => {
      error += data.toString()
    })
    
    python.on('close', (code) => {
      if (code === 0) {
        try {
          const result = JSON.parse(output)
          resolve(result)
        } catch (parseError) {
          reject(new Error(`Failed to parse algorithm output: ${parseError.message}`))
        }
      } else {
        reject(new Error(`Python script failed: ${error}`))
      }
    })
  })
}

if (require.main === module) {
  testEmergencyMatching()
    .then(() => console.log('🎉 Test completed!'))
    .catch(error => console.error('❌ Test error:', error))
}