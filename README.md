# MedChain - Blockchain-Based Emergency Medical Coordination System


## Overview

MedChain is an innovative emergency medical coordination system that connects patients in emergency situations with the most suitable hospitals using blockchain technology. The system ensures transparency, security, and trust in critical medical situations by leveraging Ethereum smart contracts and advanced matching algorithms.

## Features

### For Patients
- **Emergency Button**: Quick access to emergency services with a single tap
- **Automatic Location Detection**: Uses GPS to determine patient location
- **Smart Hospital Matching**: Connects patients to the most suitable hospital based on multiple factors
- **Navigation & Contact**: Direct navigation to hospital and one-tap calling
- **Transparent Process**: All steps are recorded on blockchain for verification

### For Hospitals
- **Resource Management**: Better distribution of patients based on capacity and specialization
- **Advance Preparation**: Receive patient information before arrival
- **Capacity Updates**: Easily update bed availability and equipment status
- **Verification System**: Verified hospital status on the blockchain
- **Performance Tracking**: Track emergency response metrics

## System Architecture

MedChain consists of four main components:

1. **Mobile Application**: Flutter-based mobile app for patients to request emergency assistance
2. **Smart Contracts**: Ethereum-based contracts that handle hospital registration, emergency creation, and matching
3. **Ocean Protocol C2D**: Compute-to-Data service that securely processes hospital and patient data
4. **Backend Services**: Services that coordinate between the blockchain, Ocean Protocol, and mobile app

## Technical Stack

- **Frontend**: Flutter/Dart
- **Blockchain**: Ethereum (Solidity)
- **Smart Contract Interaction**: ethers.js
- **Data Privacy & Computation**: Ocean Protocol Compute-to-Data
- **Location Services**: Geolocator
- **UI Components**: Custom Flutter widgets with animations

## Smart Contracts

The system uses the following main smart contracts:

- **EmergencyCoordinator.sol**: Manages emergency creation, hospital matching, and resolution
- **HospitalRegistry.sol**: Handles hospital registration, verification, and capacity updates

## Ocean Protocol Compute-to-Data

MedChain leverages Ocean Protocol's Compute-to-Data (C2D) feature as a core component of its architecture:

### What is Compute-to-Data?
- A privacy-preserving computation framework that allows algorithms to run on data without exposing the raw data
- Enables secure processing of sensitive medical information while maintaining privacy
- Provides verifiable computation with results recorded on the blockchain

### How MedChain Uses C2D
- **Private Hospital Data**: Hospitals share capacity and capability data without exposing sensitive details
- **Secure Matching Algorithm**: The matching algorithm runs within the C2D environment
- **Verifiable Results**: Each computation generates a unique Ocean job ID that's recorded on the blockchain
- **Audit Trail**: All computations are traceable and verifiable through Ocean Protocol's infrastructure

### Benefits
- **Data Privacy**: Patient and hospital data never leaves its secure environment
- **Regulatory Compliance**: Helps meet healthcare data regulations like HIPAA/GDPR
- **Trustless Computation**: Results can be verified without revealing underlying data
- **Incentivized Participation**: Hospitals can be rewarded for sharing data through Ocean's tokenomics

## Flows

### Emergency Flow
1. Patient initiates emergency through mobile app
2. System captures location and emergency details
3. Smart contract creates an emergency record on blockchain
4. Ocean Protocol C2D securely processes patient data against hospital data
5. Matching algorithm finds the best hospital match using the secure computation results
6. Smart contract updates with match results and Ocean job ID
7. Patient is directed to the matched hospital

### Hospital Flow
1. Hospital registers and gets verified in the system
2. Hospital regularly updates capacity information
3. Hospital receives emergency notifications
4. Hospital marks emergencies as resolved after treatment

## Installation & Setup

### Prerequisites
- Node.js v14+
- Flutter SDK 2.5+
- Metamask or other Ethereum wallet
- Truffle or Hardhat for contract deployment

### Smart Contract Deployment
```bash
cd contracts
npm install
npx hardhat compile
npx hardhat deploy --network <your-network>
```

### Mobile App Setup
```bash
cd mobile
flutter pub get
flutter run
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

For any inquiries, please reach out to [contact@medchain.example.com](mailto:contact@medchain.example.com)
