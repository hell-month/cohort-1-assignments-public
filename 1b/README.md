# Local development environment setup

Your goal is to successfully set up a local environment running on Docker Compose, comprising of:
- **caddy**: reverse proxy. You need to route origins of exposed ports inside Docker to a single origin with the same port. For example, if your EVM node's RPC service is running at localhost:5000 and explorer at localhost:6000, you want to route them as https://myorigin.com/rpc and https://myorigin.com/explorer.
- **ngrok**: tunnel. Sign up for ngrok and go to https://dashboard.ngrok.com/domains and get your own domain. Use the auth token and domain to tunnel your local environment to the Internet.
- **Smart contracts deployer**: this is an ephemeral container that `git clone`s your assignment 1A and runs the deployment script against your local EVM node, and then shuts down.
- **Smart contracts deployment server (caddy)**: contains information on the deployment (contract addresses). Use Caddy and very simple Caddyfile to host a web server on a [json file in this format](./example-deployment.json) containing deployed contract addresses. This file should be created by smart contracts deployer.
- **EVM node (geth)**: runs a blockchain. Just ask AI to write the entrypoint script for you.
- **Geth initialization script**: preconfigures blockchain environment. Write a short `prefund.js` script to prefund accounts for which you know the private keys, so you can use them freely. [Refer to this documentation](https://geth.ethereum.org/docs/interacting-with-geth/javascript-console#interactive-use).
- **Explorer (blockscout)**: UI to see transactions and other data. [Refer to this documentation](https://docs.blockscout.com/setup/deployment/docker-compose-deployment). Also remember that you can run two docker compose files at the same time. Blockscout needs to be connected to the local EVM node to index blockchain data. Once Blockscout is up, you will be able to see [something like this](https://coston2-explorer.flare.network/).
- **Graph stack**: indexes blockchain data & query. It consists of multiple containers (ipfs, postgres, redis, graph node). Graph node needs to be connected to ipfs, redis, postgres, and EVM node. A successful deployment would expose a GraphQL query playground that looks like something like this: https://api.goldsky.com/api/public/project_cl6mb8i9h0003e201j6li0diw/subgraphs/orderbook-subgraph/0.0.1/gn. But for now, the Graph stack does not need to index any data or host any subgraph, so you will only see **"Access deployed subgraphs by deployment ID at /subgraphs/id/<ID> or by name at /subgraphs/name/<NAME>"**. This is an expected behavior.

Each endpoint should be accessible via ngrok according to the following spec:

- Smart contracts deployment server: https://yourorigin.com/deployment
- Explorer: https://yourorigin.com/explorer
- EVM Node (RPC service): https://yourorigin.com/rpc
- Graph node GraphQL query playground: https://yourorigin.com/graph-playground

## Hints

- If something doesn't seem to be working but you don't know which container is causing the problem, try commenting out each container at a time.
- You don't have to understand every single construct on Docker Compose or every option/flag supplied to each container. As long as it works, it's fine.
- Try to leverage AI as much as possible. Use AI for the big picture, and use your manual debugging skills to resolve specific problems.
- An example repository with a slightly different configuration is at https://github.com/9oelM/xrpl-axelar-local-dev. This simulates a local EVM node connected via Axelar to an XRPL node, with other additional services.
