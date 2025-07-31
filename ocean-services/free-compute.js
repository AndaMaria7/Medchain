import axios from 'axios';
import fs from 'fs';
import path from 'path';
import FormData from 'form-data';
import { fileURLToPath } from 'url';

// Get current file directory with ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Configuration
const OCEAN_C2D_NODE = process.env.OCEAN_C2D_NODE || 'https://2.c2d.nodes.oceanprotocol.com';
const COMPUTE_API_URL = `${OCEAN_C2D_NODE}/api/v1/compute/free`;
const STATUS_API_URL = `${OCEAN_C2D_NODE}/api/v1/compute/status`;
const RESULT_API_URL = `${OCEAN_C2D_NODE}/api/v1/compute/result`;

/**
 * Start a free compute job using Ocean Provider's free compute endpoint
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
    
    // Create form data with files
    const formData = new FormData();
    
    // Add algorithm file
    const algorithmStream = fs.createReadStream(algorithmPath);
    formData.append('algorithm', algorithmStream, {
      filename: path.basename(algorithmPath),
      contentType: 'text/plain'
    });
    
    // Add dataset file
    const datasetStream = fs.createReadStream(datasetPath);
    formData.append('dataset', datasetStream, {
      filename: path.basename(datasetPath),
      contentType: 'application/json'
    });
    
    // Add additional inputs if provided
    if (additionalInputs) {
      formData.append('additionalInputs', JSON.stringify(additionalInputs));
    }
    
    // Submit compute job
    console.log('📤 Submitting files to compute service...');
    console.log(`📌 API URL: ${COMPUTE_API_URL}`);
    
    try {
      const response = await axios.post(COMPUTE_API_URL, formData, {
        headers: {
          ...formData.getHeaders(),
          'Accept': 'application/json'
        },
        maxContentLength: Infinity,
        maxBodyLength: Infinity
      });
      
      console.log('📊 Response status:', response.status);
      console.log('📄 Response data:', JSON.stringify(response.data, null, 2));
    
      if (!response.data || !response.data.jobId) {
        throw new Error('Invalid response from compute service');
      }
      
      console.log('✅ Compute job started successfully!');
      console.log('🆔 Job ID:', response.data.jobId);
      
      return {
        jobId: response.data.jobId,
        status: 'started',
        message: response.data.message || 'Job started'
      };
    } catch (error) {
      console.error('❌ Error in API call:', error.message);
      throw error;
    }
    
  } catch (error) {
    console.error('❌ Error starting compute job:', error.message);
    if (error.response) {
      console.error('📊 Error status:', error.response.status);
      console.error('📄 Error data:', JSON.stringify(error.response.data, null, 2));
    } else if (error.request) {
      console.error('📡 No response received:', error.request);
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
    
    const response = await axios.get(`${STATUS_API_URL}/${jobId}`);
    
    if (!response.data) {
      throw new Error('Invalid response from status service');
    }
    
    console.log(`📊 Job status: ${response.data.status}`);
    return response.data;
    
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
    
    const response = await axios.get(`${RESULT_API_URL}/${jobId}`);
    
    if (!response.data) {
      throw new Error('Invalid response from result service');
    }
    
    console.log('✅ Results retrieved successfully!');
    return response.data;
    
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
  
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      const status = await getComputeJobStatus(jobId);
      
      console.log(`📊 Attempt ${attempt}/${maxAttempts}: Status = ${status.status}`);
      
      if (status.status === 'succeeded') {
        console.log('🎉 Compute job completed successfully!');
        return await getComputeJobResult(jobId);
      }
      
      if (status.status === 'failed') {
        throw new Error(`Compute job failed: ${status.error || 'Unknown error'}`);
      }
      
      // Wait before next poll
      await new Promise(resolve => setTimeout(resolve, interval));
      
    } catch (error) {
      console.error(`❌ Error during polling (attempt ${attempt}):`, error.message);
      
      if (attempt === maxAttempts) {
        throw error;
      }
      
      // Wait before retry
      await new Promise(resolve => setTimeout(resolve, interval));
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
    
    // Paths to algorithm and dataset files
    const algorithmPath = path.resolve(__dirname, 'algorithm.py');
    const datasetPath = path.resolve(__dirname, 'hospitals_dataset.json');
    
    // Start compute job
    const job = await startFreeCompute(
      algorithmPath,
      datasetPath,
      { emergency: emergencyData }
    );
    
    // Poll for results
    const results = await pollForComputeResults(job.jobId);
    
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
