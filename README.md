# Hardhat Template [![Open in Gitpod][gitpod-badge]][gitpod] [![Github Actions][gha-badge]][gha] [![Hardhat][hardhat-badge]][hardhat] [![License: MIT][license-badge]][license]

[gitpod]: https://gitpod.io/#https://github.com/zama-ai/fhevm-hardhat-template
[gitpod-badge]: https://img.shields.io/badge/Gitpod-Open%20in%20Gitpod-FFB45B?logo=gitpod
[gha]: https://github.com/zama-ai/fhevm-hardhat-template/actions
[gha-badge]: https://github.com/zama-ai/fhevm-hardhat-template/actions/workflows/ci.yml/badge.svg
[hardhat]: https://hardhat.org/
[hardhat-badge]: https://img.shields.io/badge/Built%20with-Hardhat-FFDB1C.svg
[license]: https://opensource.org/licenses/MIT
[license-badge]: https://img.shields.io/badge/License-MIT-blue.svg

A Hardhat-based template for developing Solidity smart contracts, with sensible defaults.

- [Hardhat](https://github.com/nomiclabs/hardhat): compile, run and test smart contracts
- [TypeChain](https://github.com/ethereum-ts/TypeChain): generate TypeScript bindings for smart contracts
- [Ethers](https://github.com/ethers-io/ethers.js/): renowned Ethereum library and wallet implementation
- [Solhint](https://github.com/protofire/solhint): code linter
- [Solcover](https://github.com/sc-forks/solidity-coverage): code coverage
- [Prettier Plugin Solidity](https://github.com/prettier-solidity/prettier-plugin-solidity): code formatter

## Getting Started

Click the [`Use this template`](https://github.com/zama-ai/fhevm-hardhat-template/generate) button at the top of the
page to create a new repository with this repo as the initial state.

## Features

This template builds upon the frameworks and libraries mentioned above, so for details about their specific features,
please consult their respective documentations.

For example, for Hardhat, you can refer to the [Hardhat Tutorial](https://hardhat.org/tutorial) and the
[Hardhat Docs](https://hardhat.org/docs). You might be in particular interested in reading the
[Testing Contracts](https://hardhat.org/tutorial/testing-contracts) section.

### Sensible Defaults

This template comes with sensible default configurations in the following files:

```text
├── .editorconfig
├── .eslintignore
├── .eslintrc.yml
├── .gitignore
├── .prettierignore
├── .prettierrc.yml
├── .solcover.js
├── .solhint.json
└── hardhat.config.ts
```

### VSCode Integration

This template is IDE agnostic, but for the best user experience, you may want to use it in VSCode alongside Nomic
Foundation's [Solidity extension](https://marketplace.visualstudio.com/items?itemName=NomicFoundation.hardhat-solidity).

### GitHub Actions

This template comes with GitHub Actions pre-configured. Your contracts will be linted and tested on every push and pull
request made to the `main` branch.

Note though that to make this work, you must use your `INFURA_API_KEY` and your `MNEMONIC` as GitHub secrets.

You can edit the CI script in [.github/workflows/ci.yml](./.github/workflows/ci.yml).

## Usage

### Pre Requisites

Install [docker](https://docs.docker.com/engine/install/)

Install [pnpm](https://pnpm.io/installation)

Before being able to run any command, you need to create a `.env` file and set a BIP-39 compatible mnemonic as an
environment variable. You can follow the example in `.env.example`. If you don't already have a mnemonic, you can use
this [website](https://iancoleman.io/bip39/) to generate one.

Then, proceed with installing dependencies:

```sh
pnpm install
```

### Start fhevm

Start a local fhevm docker container that inlcudes everything needed to deploy FHE encrypted smart contracts

```sh
# In one terminal, keep it opened
# The node logs are printed
pnpm fhevm:start
```

To stop:

```sh
pnpm fhevm:stop
```

### Compile

Compile the smart contracts with Hardhat:

```sh
pnpm compile
```

### TypeChain

Compile the smart contracts and generate TypeChain bindings:

```sh
pnpm typechain
```

### List accounts

From the mnemonic in .env file, list all the derived Ethereum adresses:

```sh
pnpm task:accounts
```

### Get some native coins

In order to interact with the blockchain, one need some coins. This command will give coins to the first address derived
from the mnemonic in .env file.

```sh
pnpm fhevm:faucet
```

<br />
<details>
  <summary>To get the first derived address from mnemonic</summary>
<br />

```sh
pnpm task:getEthereumAddress
```

</details>
<br />

### Deploy

Deploy the ERC20 to local network:

```sh
pnpm deploy:contracts
```

Notes: <br />

<details>
<summary>Error: cannot get the transaction for EncryptedERC20's previous deployment</summary>

One can delete the local folder in deployments:

```bash
rm -r deployments/local/
```

</details>

<details>
<summary>Info: by default, the local network is used</summary>

One can change the network, check [hardhat config file](./hardhat.config.ts).

</details>
<br />

#### Mint

Run the `mint` task on the local network:

```sh
pnpm task:mint --network local --mint 1000 --account alice
```

### Test

Run the tests with Hardhat:

```sh
pnpm test
```

### Lint Solidity

Lint the Solidity code:

```sh
pnpm lint:sol
```

### Lint TypeScript

Lint the TypeScript code:

```sh
pnpm lint:ts
```

### Coverage

Generate the code coverage report:

```sh
pnpm coverage
```

### Report Gas

See the gas usage per unit test and average gas per method call:

```sh
REPORT_GAS=true pnpm test
```

### Clean

Delete the smart contract artifacts, the coverage reports and the Hardhat cache:

```sh
pnpm clean
```

### Tasks

#### Deploy EncryptedERC20

Deploy a new instance of the EncryptedERC20 contract via a task:

```sh
pnpm task:deployERC20
```

## Tips

### Syntax Highlighting

If you use VSCode, you can get Solidity syntax highlighting with the
[hardhat-solidity](https://marketplace.visualstudio.com/items?itemName=NomicFoundation.hardhat-solidity) extension.

## Using GitPod

[GitPod](https://www.gitpod.io/) is an open-source developer platform for remote development.

To view the coverage report generated by `pnpm coverage`, just click `Go Live` from the status bar to turn the server
on/off.

## Local development with Docker

Please check Evmos repository to be able to build FhEVM from sources.

## License

This project is licensed under MIT.
