# Energy Production Certification Smart Contract

## Overview
This smart contract implements a decentralized energy production certification system. The contract enables authorized certifiers to verify and certify energy production claims from producers, maintain certification records, and manage the certification process.

## Features
- Energy production certification and verification
- Authorized certifier management
- Producer certification status tracking
- Certification revocation system with detailed history
- Configurable certification parameters
- Comprehensive data storage for energy production records

## Key Components

### Roles
- **Contract Owner**: Has administrative privileges to manage certifiers and system parameters
- **Authorized Certifiers**: Can verify and certify energy producers
- **Energy Producers**: Can apply for certification of their energy production

### Core Functionality
1. **Certification Application**
   - Producers can apply for certification by submitting:
     - Energy production amount (kWh)
     - Energy source details
   - System validates production meets minimum requirements

2. **Certification Process**
   - Authorized certifiers can review and approve applications
   - Successful certification updates producer status and records
   - Maintains certification history and timestamps

3. **Revocation System**
   - Authorized parties can revoke certifications
   - Records detailed revocation history including:
     - Reason for revocation
     - Timestamp
     - Revoking authority

### Configuration Parameters
- Certification fee (in microstacks)
- Minimum energy production requirement
- Maximum allowed certification fee
- Maximum allowed production amount

## Public Functions

### Administrative Functions
- `add-certifier`: Add new authorized certifiers
- `remove-certifier`: Remove existing certifiers
- `set-certification-fee`: Update certification fee
- `set-minimum-production`: Modify minimum production requirement

### Producer Functions
- `apply-for-certification`: Submit production for certification
- `is-certified`: Check certification status
- `get-producer-data`: Retrieve production and certification details

### Certifier Functions
- `certify-producer`: Approve producer certification
- `revoke-certification`: Revoke existing certification

## Error Codes
- `err-owner-only (u100)`: Unauthorized administrative action
- `err-not-certified (u101)`: Operation on uncertified producer
- `err-already-certified (u102)`: Duplicate certification attempt
- `err-invalid-certifier (u103)`: Unauthorized certifier
- `err-invalid-amount (u104)`: Invalid production amount
- `err-not-authorized (u105)`: Insufficient permissions
- `err-invalid-fee (u106)`: Invalid fee configuration
- `err-invalid-minimum (u107)`: Invalid minimum production setting
- `err-invalid-string (u108)`: Invalid string input
- `err-invalid-reason (u109)`: Invalid revocation reason

## Data Structures

### Producer Energy Data
```clarity
{
    total-production: uint,
    last-certification-date: uint,
    energy-source: (string-ascii 30),
    certification-status: bool,
    revocation-reason: (optional (string-ascii 100)),
    revocation-date: (optional uint),
    revoked-by: (optional principal)
}
```

## Security Considerations
- Role-based access control for administrative functions
- Validation checks for all input parameters
- Maximum limits on configurable values
- Comprehensive error handling
- Permanent record keeping of certification history

## Integration Guide
1. Deploy the contract
2. Configure initial parameters (fees, minimum production)
3. Add authorized certifiers
4. Integrate with WattConnect system
5. Implement frontend interface for producers and certifiers

## Development Requirements
- Clarity smart contract language
- Stacks blockchain environment
