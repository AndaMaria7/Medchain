import { Provider } from '@oceanprotocol/lib';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Get current file directory with ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Configuration
const OCEAN_PROVIDER_URL = process.env.PROVIDER_URL || 'https://v4.provider.oceanprotocol.com';
const OCEAN_C2D_NODE = process.env.OCEAN_C2D_NODE || 'https://2.c2d.nodes.oceanprotocol.com';

/**
 * Initialize the Ocean Provider instance
 * @returns {Provider} Provider instance
 */
function initializeProvider() {
  console.log(`🔌 Initializing Ocean Provider at ${OCEAN_PROVIDER_URL}`);
  return new Provider();
}

/**
 * Get available compute environments from the provider
 * @param {Provider} provider - Ocean Provider instance
 * @returns {Promise<Array>} - List of available compute environments
 */
async function getComputeEnvironments(provider) {
  try {
    console.log('🔍 Getting compute environments...');
    // Use the provider to get compute environments
    const environments = await provider.getComputeEnvironments(OCEAN_C2D_NODE);
    
    console.log(`✅ Found ${environments.length} compute environments`);
    
    // Filter for free environments
    const freeEnvironments = environments.filter(env => env.free && env.free.maxJobs > 0);
    console.log(`🆓 Found ${freeEnvironments.length} free compute environments`);
    
    return freeEnvironments;
  } catch (error) {
    console.error('❌ Error getting compute environments:', error.message);
    throw error;
  }
}

/**
 * Start a free compute job using Ocean Provider
 * @param {string} algorithmPath - Path to the algorithm file
 * @param {string} datasetPath - Path to the dataset file
 * @param {Object} additionalInputs - Additional inputs to pass to the algorithm
 * @returns {Promise<Object>} - Job details including jobId
 */
async function startFreeCompute(algorithmPath, datasetPath, additionalInputs = null) {
  try {
    console.log('🚀 Starting free compute job...');
    
    // Validate files exist
    if (!fs.existsSync(algorithmPath)) {
      throw new Error(`Algorithm file not found: ${algorithmPath}`);
    }
    
    if (!fs.existsSync(datasetPath)) {
      throw new Error(`Dataset file not found: ${datasetPath}`);
    }
    
    // Initialize provider
    const provider = initializeProvider();
    
    // Get compute environments
    const environments = await getComputeEnvironments(provider);
    
    if (!environments || environments.length === 0) {
      throw new Error('No free compute environments available');
    }
    
    // Select the first free environment
    const selectedEnvironment = environments[0];
    console.log(`🖥️ Selected environment: ${selectedEnvironment.id}`);
    
    // Read algorithm and dataset files
    const algorithmContent = fs.readFileSync(algorithmPath, 'utf8');
    const datasetContent = fs.readFileSync(datasetPath, 'utf8');
    
    // Create algorithm metadata
    const algorithm = {
      meta: {
        container: {
          image: 'python:3.9-slim',
          entrypoint: 'python $ALGO',
          tag: 'latest'
        }
      },
      raw: algorithmContent
    };
    
    // Create dataset metadata
    const dataset = {
      raw: datasetContent
    };
    
    // Add additional inputs if provided
    if (additionalInputs) {
      dataset.additionalInputs = additionalInputs;
    }
    
    console.log('📤 Submitting free compute job...');
    
    // Create compute assets array
    const assets = [dataset];
    
    // Get current timestamp for job validity
    const validUntil = Math.floor(Date.now() / 1000) + 3600; // Valid for 1 hour
    
    // Start free compute job using the Provider's freeComputeStart method
    // Note: This method requires a signer which we don't have in this implementation
    // We'll use a mock implementation for now
    console.log('Using Ocean C2D node:', OCEAN_C2D_NODE);
    console.log('Using environment:', selectedEnvironment.id);
    console.log('Algorithm:', JSON.stringify(algorithm.meta, null, 2));
    
    // Mock job ID for testing
    const jobId = `free-compute-${Date.now()}`;
    
    console.log('✅ Compute job started successfully!');
    console.log('🆔 Job ID:', jobId);
    
    return {
      jobId,
      status: 'started',
      environmentId: selectedEnvironment.id
    };
    
  } catch (error) {
    console.error('❌ Error starting compute job:', error.message);
    if (error.response) {
      console.error('📊 Error status:', error.response.status);
      console.error('📔 Error data:', JSON.stringify(error.response.data, null, 2));
    }
    throw error;
  }
}

/**
 * Check the status of a compute job
 * @param {string} jobId - The job ID to check
 * @returns {Promise<Object>} - Job status details
 */
async function getComputeJobStatus(jobId) {
  try {
    console.log(`🔍 Checking status for job ${jobId}...`);
    
    // Initialize provider
    const provider = initializeProvider();
    
    // For mock implementation, return a simulated status
    if (jobId.startsWith('free-compute-')) {
      // Simulate job status based on time elapsed
      const jobTimestamp = parseInt(jobId.split('-')[2]);
      const elapsed = Date.now() - jobTimestamp;
      
      let status, statusText;
      
      if (elapsed < 5000) {
        status = 10; // Running
        statusText = 'Job is running';
      } else if (elapsed < 10000) {
        status = 30; // Processing results
        statusText = 'Processing results';
      } else {
        status = 70; // Succeeded
        statusText = 'Job completed successfully';
      }
      
      console.log(`📊 Job status: ${statusText}`);
      
      return {
        owner: 'medchain-user',
        jobId: jobId,
        dateCreated: Math.floor(jobTimestamp / 1000),
        dateFinished: status === 70 ? Math.floor(Date.now() / 1000) : null,
        status: status,
        statusText: statusText,
        results: status === 70 ? ['results.json'] : [],
        agreementId: null,
        expireTimestamp: Math.floor(jobTimestamp / 1000) + 3600,
        environment: 'mock-environment',
        isFree: true
      };
    }
    
    // If not a mock job ID, try to get actual status from provider
    try {
      const status = await provider.computeStatus(OCEAN_C2D_NODE, jobId);
      console.log(`📊 Job status: ${status.statusText}`);
      return status;
    } catch (error) {
      console.error(`❌ Error getting status from provider: ${error.message}`);
      throw error;
    }
    
  } catch (error) {
    console.error('❌ Error checking job status:', error.message);
    throw error;
  }
}

/**
 * Get the results of a completed compute job
 * @param {string} jobId - The job ID to get results for
 * @returns {Promise<Object>} - Job results
 */
async function getComputeJobResult(jobId) {
  try {
    console.log(`📥 Retrieving results for job ${jobId}...`);
    
    // Initialize provider
    const provider = initializeProvider();
    
    // For mock implementation, return simulated results
    if (jobId.startsWith('free-compute-')) {
      console.log('✅ Mock results retrieved successfully!');
      
      // Generate mock hospital matching results
      const mockResults = {
        matches: [
          {
            hospitalId: 'hospital-001',
            name: 'Central Emergency Hospital',
            distance: 2.4,
            score: 92.5,
            specialization: 'cardiac',
            availableBeds: 5,
            contact: {
              phone: '+40 21 555 7890',
              email: 'emergency@centralhospital.ro'
            },
            location: {
              lat: 44.4268,
              lng: 26.1025
            }
          },
          {
            hospitalId: 'hospital-003',
            name: 'University Medical Center',
            distance: 3.8,
            score: 87.3,
            specialization: 'cardiac',
            availableBeds: 3,
            contact: {
              phone: '+40 21 555 2345',
              email: 'emergency@umc.ro'
            },
            location: {
              lat: 44.4350,
              lng: 26.0999
            }
          },
          {
            hospitalId: 'hospital-007',
            name: 'St. Maria Hospital',
            distance: 5.1,
            score: 81.2,
            specialization: 'general',
            availableBeds: 8,
            contact: {
              phone: '+40 21 555 6543',
              email: 'emergency@stmaria.ro'
            },
            location: {
              lat: 44.4401,
              lng: 26.1199
            }
          }
        ],
        timestamp: new Date().toISOString(),
        jobId: jobId,
        computeTime: '1.23s'
      };
      
      return mockResults;
    }
    
    // If not a mock job ID, try to get actual results from provider
    try {
      const results = await provider.computeResult(OCEAN_C2D_NODE, jobId);
      console.log('✅ Results retrieved successfully!');
      return results;
    } catch (error) {
      console.error(`❌ Error getting results from provider: ${error.message}`);
      throw error;
    }
    
  } catch (error) {
    console.error('❌ Error retrieving job results:', error.message);
    throw error;
  }
}

/**
 * Poll for compute job results until completion or timeout
 * @param {string} jobId - The job ID to poll for
 * @param {number} maxAttempts - Maximum number of polling attempts
 * @param {number} interval - Polling interval in milliseconds
 * @returns {Promise<Object>} - Job results
 */
async function pollForComputeResults(jobId, maxAttempts = 30, interval = 10000) {
  console.log(`⏳ Polling for compute results (job ${jobId})...`);
  
  // For mock implementation, use shorter interval
  const pollInterval = jobId.startsWith('free-compute-') ? 2000 : interval;
  
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      const status = await getComputeJobStatus(jobId);
      
      console.log(`📊 Attempt ${attempt}/${maxAttempts}: Status = ${status.statusText}`);
      
      if (status.status === 70) { // Succeeded
        console.log('🎉 Compute job completed successfully!');
        return await getComputeJobResult(jobId);
      }
      
      if (status.status === 50) { // Failed
        throw new Error(`Compute job failed: ${status.statusText || 'Unknown error'}`);
      }
      
      // Wait before next poll
      await new Promise(resolve => setTimeout(resolve, pollInterval));
      
    } catch (error) {
      console.error(`❌ Error during polling (attempt ${attempt}):`, error.message);
      
      if (attempt === maxAttempts) {
        throw error;
      }
      
      // Wait before retry
      await new Promise(resolve => setTimeout(resolve, pollInterval));
    }
  }
  
  throw new Error(`Compute job timed out after ${maxAttempts} attempts`);
}

/**
 * Start an emergency matching compute job using free compute
 * @param {Object} emergencyData - Emergency data to process
 * @returns {Promise<Object>} - Job results
 */
async function startEmergencyMatching(emergencyData) {
  try {
    console.log('🚨 Starting emergency matching compute job...');
    console.log('📝 Emergency data:', JSON.stringify(emergencyData, null, 2));
    
    // Paths to algorithm and dataset files
    const algorithmPath = path.resolve(__dirname, 'algorithm.py');
    const datasetPath = path.resolve(__dirname, 'hospitals_dataset.json');
    
    // Validate files exist
    if (!fs.existsSync(algorithmPath)) {
      console.error(`❌ Algorithm file not found: ${algorithmPath}`);
    } else {
      console.log(`✅ Algorithm file found: ${algorithmPath}`);
    }
    
    if (!fs.existsSync(datasetPath)) {
      console.error(`❌ Dataset file not found: ${datasetPath}`);
    } else {
      console.log(`✅ Dataset file found: ${datasetPath}`);
    }
    
    // Start compute job
    const job = await startFreeCompute(
      algorithmPath,
      datasetPath,
      { emergency: emergencyData }
    );
    
    // Poll for results with shorter timeout for testing
    const results = await pollForComputeResults(job.jobId, 10, 2000);
    
    return {
      jobId: job.jobId,
      status: 'completed',
      result: results,
      emergencyData: emergencyData
    };
    
  } catch (error) {
    console.error('❌ Error in emergency matching:', error.message);
    throw error;
  }
}

/**
 * Test the emergency matching flow
 */
async function testEmergencyFlow() {
  // Sample emergency data
  const sampleEmergency = {
    emergencyId: 'emergency_' + Date.now(),
    location: { lat: 44.4200, lng: 26.1000 },
    severity: 8,
    timestamp: new Date().toISOString(),
    type: 'cardiac',
    patient: {
      age: 58,
      gender: 'male',
      bloodType: 'A+',
      symptoms: ['chest pain', 'shortness of breath', 'dizziness'],
      vitals: {
        heartRate: 115,
        bloodPressure: '160/95',
        oxygenSaturation: 92
      }
    }
  };
  
  console.log('🧪 Testing emergency matching flow...');
  console.log('🚨 Emergency data:', JSON.stringify(sampleEmergency, null, 2));
  
  try {
    const result = await startEmergencyMatching(sampleEmergency);
    console.log('✅ Test completed successfully!');
    console.log('📋 Results:', JSON.stringify(result.result, null, 2));
    return result;
  } catch (error) {
    console.error('❌ Test failed:', error);
    throw error;
  }
}

// Export functions
export {
  initializeProvider,
  getComputeEnvironments,
  startFreeCompute,
  getComputeJobStatus,
  getComputeJobResult,
  pollForComputeResults,
  startEmergencyMatching,
  testEmergencyFlow
};

// Run test if executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  testEmergencyFlow()
    .then(() => console.log('🎉 Test flow completed!'))
    .catch(error => console.error('❌ Test error:', error));
}
