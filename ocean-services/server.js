import dotenv from 'dotenv'
dotenv.config()

import express from 'express'
import cors from 'cors'
import bodyParser from 'body-parser'
import { startEmergencyMatching, pollForResults } from './compute.js'

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Store active jobs
const jobs = new Map();

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', ocean_connected: true });
});

// Start emergency compute
app.post('/emergency/start', async (req, res) => {
  try {
    const { patientData, emergencyType, location } = req.body;
    
    const emergencyPayload = {
      emergencyId: 'emergency_' + Date.now(),
      location: location || { lat: 44.4200, lng: 26.1000 },
      severity: patientData.severity || 7,
      timestamp: new Date().toISOString(),
      type: emergencyType,
      patient: patientData
    };

    console.log('🚨 Starting emergency compute for:', emergencyType);
    
    const result = await startEmergencyMatching(emergencyPayload);
    
    jobs.set(result.jobId, {
      id: result.jobId,
      status: 'completed', 
      result: result.result,
      emergencyData: result.emergencyData,
      startTime: new Date()
    });

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

app.get('/job/:jobId', (req, res) => {
  const job = jobs.get(req.params.jobId);
  if (!job) {
    return res.status(404).json({ error: 'Job not found' });
  }
  res.json(job);
});

app.listen(PORT, () => {
  console.log(`🚀 MedChain server running on port ${PORT}`);
});