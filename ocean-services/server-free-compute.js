import express from 'express';
import cors from 'cors';
import bodyParser from 'body-parser';
import { startEmergencyMatching } from './ocean-free-compute.js';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3002;

// Enable CORS and JSON parsing
app.use(cors());
app.use(express.json());
app.use(bodyParser.json());

// Store active jobs
const jobs = new Map();

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    service: 'MedChain Free Compute Service',
    ocean_c2d_node: process.env.OCEAN_C2D_NODE || 'https://2.c2d.nodes.oceanprotocol.com'
  });
});

// Start emergency compute endpoint
app.post('/emergency/start', async (req, res) => {
  try {
    const { patientData, emergencyType, location } = req.body;
    
    // Create emergency payload
    const emergencyPayload = {
      emergencyId: 'emergency_' + Date.now(),
      location: location || { lat: 44.4200, lng: 26.1000 },
      severity: patientData.severity || 7,
      timestamp: new Date().toISOString(),
      type: emergencyType,
      patient: patientData
    };

    console.log('🚨 Starting emergency compute for:', emergencyType);
    console.log('📍 Location:', JSON.stringify(location));
    
    // Start compute job
    const result = await startEmergencyMatching(emergencyPayload);
    
    // Store job in memory
    jobs.set(result.jobId, {
      id: result.jobId,
      status: 'completed',
      result: result.result,
      emergencyData: result.emergencyData,
      startTime: new Date()
    });

    // Return response to client
    res.json({ 
      jobId: result.jobId,
      status: 'completed',
      result: result.result 
    });

  } catch (error) {
    console.error('❌ Emergency compute failed:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get job status endpoint
app.get('/emergency/status/:jobId', (req, res) => {
  const jobId = req.params.jobId;
  const job = jobs.get(jobId);
  
  if (!job) {
    return res.status(404).json({ error: 'Job not found' });
  }
  
  res.json({
    jobId: job.id,
    status: job.status,
    startTime: job.startTime
  });
});

// Get job result endpoint
app.get('/emergency/result/:jobId', (req, res) => {
  const jobId = req.params.jobId;
  const job = jobs.get(jobId);
  
  if (!job) {
    return res.status(404).json({ error: 'Job not found' });
  }
  
  if (job.status !== 'completed') {
    return res.status(400).json({ error: 'Job not completed yet' });
  }
  
  res.json({
    jobId: job.id,
    result: job.result
  });
});

// Get job status endpoint - compatible with Flutter client
app.get('/job/:jobId', (req, res) => {
  const jobId = req.params.jobId;
  const job = jobs.get(jobId);
  
  console.log(`📊 Flutter client requesting job status for: ${jobId}`);
  
  if (!job) {
    console.log(`❌ Job not found: ${jobId}`);
    return res.status(404).json({ 
      status: 'not_found',
      id: jobId,
      error: 'Job not found' 
    });
  }
  
  // Extract the best match from the results if available
  let bestMatch = null;
  let matchScore = 0;
  
  if (job.result && job.result.matches && job.result.matches.length > 0) {
    // Get the first (best) match
    bestMatch = job.result.matches[0];
    matchScore = bestMatch.score || 0;
  }
  
  // Format response to match what the Flutter client expects
  res.json({
    id: job.id,
    status: job.status,
    progress: job.status === 'completed' ? 100 : 50,
    result: {
      ...job.result,
      // Add these specific fields that the Flutter client expects
      matched_hospital_id: bestMatch ? bestMatch.hospitalId : null,
      match_score: matchScore,
      best_match: bestMatch
    },
    startTime: job.startTime
  });
});

// Start the server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 MedChain Free Compute server running on port ${PORT}`);
  console.log(`🌊 Using Ocean C2D node: ${process.env.OCEAN_C2D_NODE || 'https://2.c2d.nodes.oceanprotocol.com'}`);
});
