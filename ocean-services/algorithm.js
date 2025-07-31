const { config, wallet, oceanNode } = require('./config')
const fs = require('fs')

// Emergency matching algorithm code
const algorithmCode = `
import json
import math
import sys

def calculate_distance(lat1, lon1, lat2, lon2):
    """Calculate distance between two points in kilometers"""
    R = 6371  # Earth's radius in kilometers
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (math.sin(dlat/2) * math.sin(dlat/2) +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
         math.sin(dlon/2) * math.sin(dlon/2))
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    return R * c

def emergency_matching_algorithm(hospitals, emergency):
    """
    AI algorithm that matches emergency with best hospital
    Returns the hospital with highest matching score
    """
    best_hospital = None
    best_score = 0
    
    emergency_lat = emergency['location']['lat']
    emergency_lng = emergency['location']['lng']
    emergency_severity = emergency['severity']
    
    results = []
    
    for hospital in hospitals:
        score = 0
        
        # Distance factor (closer is better, max 50 points)
        distance = calculate_distance(
            emergency_lat, emergency_lng,
            hospital['location']['lat'], hospital['location']['lng']
        )
        distance_score = max(0, 50 - distance)
        score += distance_score
        
        # Capacity factor
        if emergency_severity >= 8:  # Critical emergency
            if hospital['icu_beds_available'] > 0:
                score += 30
            if hospital['has_cardiac_surgery']:
                score += 20
        else:  # Regular emergency
            if hospital['emergency_beds_available'] > 0:
                score += 25
        
        # Wait time factor (shorter wait is better, max 30 points)
        wait_time_score = max(0, 30 - hospital['average_wait_time_minutes'])
        score += wait_time_score
        
        # Specialization factor
        if hospital['has_trauma_center']:
            score += 15
        
        results.append({
            'hospital_id': hospital['hospital_id'],
            'score': score,
            'distance_km': distance,
            'reasoning': f"Distance: {distance:.1f}km, Capacity: {hospital['icu_beds_available']}ICU/{hospital['emergency_beds_available']}ER, Wait: {hospital['average_wait_time_minutes']}min"
        })
        
        if score > best_score:
            best_score = score
            best_hospital = hospital
    
    return {
        'matched_hospital_id': best_hospital['hospital_id'] if best_hospital else None,
        'match_score': best_score,
        'distance_km': calculate_distance(
            emergency_lat, emergency_lng,
            best_hospital['location']['lat'], best_hospital['location']['lng']
        ) if best_hospital else 0,
        'all_hospitals': results,
        'reasoning': 'Selected based on distance, capacity, wait time, and specialization',
        'emergency_severity': emergency_severity
    }

# Main execution
if __name__ == "__main__":
    # Read input data from command line arguments
    hospitals_data = json.loads(sys.argv[1])
    emergency_data = json.loads(sys.argv[2])
    
    # Run matching algorithm
    result = emergency_matching_algorithm(hospitals_data, emergency_data)
    
    # Output result as JSON
    print(json.dumps(result, indent=2))
`

async function prepareMatchingAlgorithm() {
  try {
    console.log('🤖 Preparing emergency matching algorithm...')
    
    // Create algorithm metadata
    const metadata = {
      "@context": ["https://w3id.org/did/v1"],
      id: "", // Will be generated
      version: "4.1.0",
      chainId: config.chainId,
      metadata: {
        created: new Date().toISOString(),
        updated: new Date().toISOString(),
        type: "algorithm",
        name: 'Emergency Hospital Matching Algorithm',
        description: 'AI algorithm that matches emergency cases with optimal hospitals based on distance, capacity, and specialization',
        author: wallet.address,
        license: 'MIT',
        tags: ['ai', 'emergency', 'matching', 'algorithm', 'healthcare'],
        algorithm: {
          language: 'python',
          format: 'docker-image',
          version: '1.0',
          container: {
            entrypoint: 'python algorithm.py',
            image: 'python:3.9-slim',
            tag: 'latest'
          }
        }
      },
      services: [
        {
          id: "compute",
          type: "compute",
          files: [
            {
              type: "url",
              url: `data:text/plain;base64,${Buffer.from(algorithmCode).toString('base64')}`,
              method: "GET"
            }
          ],
          datatokenAddress: "", // Will be set after datatoken creation
          serviceEndpoint: config.computeEndpoint,
          timeout: 3600,
          compute: {
            allowRawAlgorithm: true,
            allowNetworkAccess: false,
            publisherTrustedAlgorithms: []
          }
        }
      ]
    }
    
    const algorithmInfo = {
      name: 'Emergency Hospital Matching Algorithm',
      metadata: metadata,
      algorithm_code: algorithmCode,
      created_at: new Date().toISOString(),
      status: 'prepared' // Not yet published to Ocean Node
    }
    
    // Save algorithm info
    fs.writeFileSync('algorithm_asset.json', JSON.stringify(algorithmInfo, null, 2))
    
    console.log('✅ Algorithm prepared successfully!')
    console.log('📍 Algorithm: Emergency Hospital Matching')
    console.log('🐍 Language: Python 3.9')
    console.log('💾 Code size:', algorithmCode.length, 'bytes')
    console.log('📋 Algorithm details saved to algorithm_asset.json')
    
    return algorithmInfo
    
  } catch (error) {
    console.error('❌ Error preparing algorithm:', error.message)
    throw error
  }
}

module.exports = { 
  prepareMatchingAlgorithm, 
  algorithmCode 
}

if (require.main === module) {
  prepareMatchingAlgorithm()
    .then(() => console.log('🎉 Algorithm prepared!'))
    .catch(error => console.error('❌ Error:', error))
}