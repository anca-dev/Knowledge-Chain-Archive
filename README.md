# KnowledgeChain Archive

A decentralized knowledge base built on Stacks blockchain for AI researchers to publish papers, code, and datasets with immutable timestamps, attribution tracking, and automated revenue sharing.

## Overview

KnowledgeChain Archive creates a transparent academic publishing platform where researchers maintain ownership of their work while ensuring proper attribution through on-chain citation tracking. The system supports various access levels and automated revenue distribution for referenced work.

## Features

- **Immutable Publication**: Timestamped publishing with content-addressable storage (IPFS)
- **Attribution Tracking**: Automatic citation counting and authorship verification
- **Access Control**: Three-tier permission system (public, restricted, private)
- **Citation Management**: On-chain citation relationships between artifacts
- **Author Metrics**: Track publications, citations, and revenue per author
- **Revenue Sharing**: Automated tracking of revenue generated from referenced work

## Smart Contract Functions

### Read-Only Functions

- `get-artifact (artifact-id uint)`: Retrieve artifact details
- `get-citation (citation-id uint)`: Get citation information
- `get-author-stats (author principal)`: View author's publication metrics
- `has-access (artifact-id uint, user principal)`: Check if user can access artifact
- `get-citation-count (artifact-id uint)`: Get number of times artifact is cited

### Public Functions

- `publish-artifact (title, content-hash, artifact-type, access-level)`: Publish new research artifact
- `add-citation (citing-artifact-id, cited-artifact-id)`: Record citation relationship
- `grant-access (artifact-id, user)`: Grant user access to restricted artifact
- `revoke-access (artifact-id, user)`: Remove user's access permissions
- `update-access-level (artifact-id, new-access-level)`: Change artifact's access level
- `record-revenue (artifact-id, amount)`: Record revenue generated (owner only)

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- IPFS node or pinning service for content storage
- Stacks wallet

### Installation
```bash
git clone <repository-url>
cd knowledge-archive
clarinet check
```

### Testing
```bash
clarinet test
clarinet console
```

## Usage Example
```clarity
;; Publish a research paper (public access)
(contract-call? .knowledge-archive publish-artifact 
  "Neural Network Optimization Techniques"
  "QmX3fG7h8K9j2L1mN4o5P6q7R8s9T0u1V2w3X4y5Z6a7B8c"
  "paper"
  u0)

;; Publish dataset (restricted access)
(contract-call? .knowledge-archive publish-artifact
  "Training Dataset for LLM Fine-tuning"
  "QmA1b2C3d4E5f6G7h8I9j0K1l2M3n4O5p6Q7r8S9t0U1v2"
  "dataset"
  u1)

;; Grant access to specific user
(contract-call? .knowledge-archive grant-access u1 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)

;; Add citation from your paper to another
(contract-call? .knowledge-archive add-citation u2 u0)

;; Check citation count
(contract-call? .knowledge-archive get-citation-count u0)

;; View author statistics
(contract-call? .knowledge-archive get-author-stats tx-sender)
```

## Artifact Types

Supported artifact types:
- `paper`: Research papers and articles
- `code`: Source code and algorithms
- `dataset`: Training and test datasets
- `model`: Trained AI models
- `notebook`: Jupyter notebooks and analyses
- `preprint`: Pre-publication drafts

## Access Levels

- **Public (0)**: Accessible by anyone
- **Restricted (1)**: Requires explicit permission from author
- **Private (2)**: Only accessible by author

## Technical Details

- **Content Addressing**: Uses IPFS hashes (64-character ASCII strings)
- **Citation Tracking**: Bidirectional citation relationships
- **Immutability**: Published artifacts cannot be modified (publish new versions instead)
- **Author Verification**: Cryptographic proof of authorship via Stacks addresses

## Revenue Sharing Model

The contract tracks revenue generated when artifacts are referenced or used:
- Authors retain ownership of revenue distribution rights
- Citation counts influence revenue allocation
- Transparent on-chain tracking of all revenue

## Security Considerations

- Authors have exclusive control over their artifacts
- Access permissions can be granted and revoked by authors
- Only contract owner can record revenue (integration with payment systems)
- Content hashes ensure data integrity
- Citations cannot be removed once added

## Use Cases

1. **Academic Publishing**: Publish research with verifiable timestamps
2. **Dataset Sharing**: Share training data with access controls
3. **Open Source AI**: Release models with proper attribution
4. **Collaborative Research**: Track contributions across projects
5. **IP Protection**: Establish prior art with blockchain timestamps

## Future Enhancements

- Versioning system for artifacts
- Peer review integration
- Reputation scoring for authors
- Automated revenue distribution in STX
- NFT minting for significant publications
- Cross-chain citation tracking