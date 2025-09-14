const from = eth.accounts[0];
const contractDeployer = "0x8C02659432BC4482c4380dE8bDc9e3DeE61f1868";
eth.sendTransaction({
  from: from,
  to: contractDeployer,
  value: web3.toWei(100, "ether"),
});

// SK : 29ce8bb6678440ab77b4f3b78c8433985b4d312a741720375cedc7b6d8e5d6a8
