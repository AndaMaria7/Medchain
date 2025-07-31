#!/usr/bin/env python
# Ocean Protocol Free Compute Algorithm for Emergency Hospital Matching
# This algorithm matches emergency cases to the most suitable hospital

import json
import os
import sys
import math
from datetime import datetime

# Function to calculate distance between two points using Haversine formula
def calculate_distance(lat1, lon1, lat2, lon2):
    # Convert latitude and longitude from degrees to radians
    lat1, lon1, lat2, lon2 = map(math.radians, [lat1, lon1, lat2, lon2])
    
    # Haversine formula
    dlon = lon2 - lon1
    dlat = lat2 - lat1
    a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
    c = 2 * math.asin(math.sqrt(a))
    r = 6371  # Radius of earth in kilometers
    return c * r

# Function to calculate hospital score based on distance, capacity, and specialization
def calculate_hospital_score(hospital, emergency):
    # Extract emergency details
    emergency_type = emergency.get('type', '').lower()
    emergency_location = emergency.get('location', {})
    emergency_severity = emergency.get('severity', 5)  # Default to medium severity
    
    # Extract hospital details
    hospital_location = hospital.get('location', {})
    hospital_capacity = hospital.get('capacity', 0)
    hospital_specializations = [s.lower() for s in hospital.get('specializations', [])]
    
    # Calculate distance score (closer is better)
    distance = calculate_distance(
        emergency_location.get('lat', 0),
        emergency_location.get('lng', 0),
        hospital_location.get('lat', 0),
        hospital_location.get('lng', 0)
    )
    
    # Normalize distance score (0-10, where 10 is closest)
    # Assume max reasonable distance is 50km
    distance_score = max(0, 10 - (distance / 5))
    
    # Calculate specialization match score
    specialization_score = 0
    if emergency_type == 'cardiac' and 'cardiology' in hospital_specializations:
        specialization_score = 10
    elif emergency_type == 'trauma' and 'emergency' in hospital_specializations:
        specialization_score = 10
    elif emergency_type == 'stroke' and 'neurology' in hospital_specializations:
        specialization_score = 10
    elif 'emergency' in hospital_specializations:
        specialization_score = 5  # General emergency capability
    
    # Calculate capacity score (0-10, where 10 is highest capacity)
    capacity_score = min(10, hospital_capacity / 10)
    
    # Calculate final score with weights
    # Distance is most important, then specialization, then capacity
    final_score = (distance_score * 0.5) + (specialization_score * 0.3) + (capacity_score * 0.2)
    
    return {
        'hospital_id': hospital.get('id'),
        'hospital_name': hospital.get('name'),
        'distance_km': round(distance, 2),
        'score': round(final_score, 2),
        'specialization_match': specialization_score > 5,
        'capacity': hospital.get('capacity')
    }

def main():
    # Print algorithm start message
    print("🏥 Starting Emergency Hospital Matching Algorithm")
    
    # Get paths for input and output
    dataset_path = os.path.join(os.path.dirname(os.path.realpath(__file__)), "inputs/dataset")
    algorithm_path = os.path.join(os.path.dirname(os.path.realpath(__file__)), "inputs/algorithm")
    output_path = os.path.join(os.path.dirname(os.path.realpath(__file__)), "outputs")
    
    # Ensure output directory exists
    os.makedirs(output_path, exist_ok=True)
    
    try:
        # Load hospitals dataset
        with open(dataset_path, 'r') as f:
            hospitals_data = json.load(f)
            
        # Load emergency data from algorithm inputs
        with open(algorithm_path, 'r') as f:
            algorithm_data = json.load(f)
            
        # Extract emergency data
        emergency_data = algorithm_data.get('emergency', {})
        
        if not emergency_data:
            raise ValueError("No emergency data provided in algorithm inputs")
            
        print(f"🚨 Processing emergency: {emergency_data.get('type')} (ID: {emergency_data.get('emergencyId')})")
        
        # Calculate scores for each hospital
        hospital_scores = []
        for hospital in hospitals_data:
            score = calculate_hospital_score(hospital, emergency_data)
            hospital_scores.append(score)
        
        # Sort hospitals by score (highest first)
        hospital_scores.sort(key=lambda x: x['score'], reverse=True)
        
        # Take top 3 matches
        top_matches = hospital_scores[:3]
        
        # Prepare result
        result = {
            'emergency_id': emergency_data.get('emergencyId'),
            'emergency_type': emergency_data.get('type'),
            'emergency_severity': emergency_data.get('severity'),
            'timestamp': datetime.now().isoformat(),
            'matches': top_matches,
            'best_match': top_matches[0] if top_matches else None
        }
        
        # Write result to output file
        output_file = os.path.join(output_path, 'result.json')
        with open(output_file, 'w') as f:
            json.dump(result, f, indent=2)
            
        print(f"✅ Emergency matching completed. Found {len(top_matches)} suitable hospitals.")
        print(f"🥇 Best match: {top_matches[0]['hospital_name']} (Score: {top_matches[0]['score']})")
        
    except Exception as e:
        error_message = f"❌ Error in hospital matching algorithm: {str(e)}"
        print(error_message, file=sys.stderr)
        
        # Write error to output
        error_file = os.path.join(output_path, 'error.txt')
        with open(error_file, 'w') as f:
            f.write(error_message)
        
        sys.exit(1)

if __name__ == "__main__":
    main()
