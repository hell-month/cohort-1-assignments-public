#!/usr/bin/env node

const fs = require('fs');

// Path to the broadcast artifact (inside container)
const broadcastPath = './cohort-1-assignments-public/1a/broadcast/MiniAMM.s.sol/1337/run-latest.json';

try {
  // Read the broadcast artifact
  const broadcastData = JSON.parse(fs.readFileSync(broadcastPath, 'utf8'));
  
  // Extract contract addresses from transactions
  const contracts = {
    mock_erc_0: null,
    mock_erc_1: null,
    mini_amm: null
  };
  
  let mockErcCount = 0;
  
  for (const tx of broadcastData.transactions) {
    if (tx.transactionType === 'CREATE') {
      if (tx.contractName === 'MockERC20') {
        if (mockErcCount === 0) {
          contracts.mock_erc_0 = tx.contractAddress;
        } else if (mockErcCount === 1) {
          contracts.mock_erc_1 = tx.contractAddress;
        }
        mockErcCount++;
      } else if (tx.contractName === 'MiniAMM') {
        contracts.mini_amm = tx.contractAddress;
      }
    }
  }
  
  // Write the deployment JSON
  fs.writeFileSync('./deployment.json', JSON.stringify(contracts, null, 4));
  
  console.log('✅ Contract addresses extracted to deployment.json:');
  console.log(JSON.stringify(contracts, null, 2));
  
} catch (error) {
  console.error('❌ Error:', error.message);
  process.exit(1);
}