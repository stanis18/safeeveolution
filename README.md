# Safe Creation and Upgrade of Ethereum Smart Contracts via a TrustedDeployer!

 

## Introduction

Smart contracts is a term used to describe computer code that is capable of self-execute business agreements between parties. Although they can hold millions of dollars’ worth of digital assets, there is still a great deal of difficulty in determining during the development process whether the smart contract will actually perform its functions as expected. To help to tackle these problems we propose TrustedDeployer. A systematic framework,  based on the design-by-contract methodology, targeting the Ethereum platform, that requires smart contracts to be formally verified before deployment. Ensuring that smart contracts are created and upgraded when they met their expected specification. We evaluate our framework on a number of real-world contracts to illustrate the benefits that our framework could have in real life. Even though formal verification is a very computationally-intensive process, our evaluation demonstrates that the sort of application we propose seems very tractable. In order to auxiliate the process developed on this project we used [solc-verify](https://github.com/SRI-CSL/solidity/blob/boogie/SOLC-VERIFY-README.md) (**v0.5.17**) , a source-level verification tool built on top of the Solidity compiler, and invariants, pre- and post-conditions are provided as annotations.


## Repositories


Although it is a consensus among  academic researchers that the use of formal analysis tools can help to increase the quality and reliability of software, it is still a cumbersome task to integrate them in the daily software-development process. So, to help to fill the gap between industry and academia, after proposing our new approach for safe creation and evolution of smart contracts, we designed an experiment, in order to show how simple and adaptable for various scenarios our framework can be. Our examples were based on ERC20 and ERC1155  standards. Even though, these standards were developed by the ethereum community as a way of organizing and disseminate the knowledge among the stakeholders, there are still problems related to the use of natural language, because they are inherently ambiguous, in addition there is a great difficulty in maintaining traceability between requirements and code.


**ERC20**

Proposed in 2015 by Vitalik Buterin, ERC20 it is one of the first stan-dards defined for the ethereum platform, and is also one of the most used, withmore than 360000 thousand active tokens on the network. Since it was created,there have been several critical flaws related to its development that have led tolarge financial losses. Several  initiatives  have  emerged  with  proposals  to  deal  with  these  problems,one of which, OpenZeppelin, provides solutions to build, automate and operate decentralized application. We selected 9 ERC20 open repositories to run the experiment.

[Ambrosus](https://github.com/ambrosus/Ambrosus.git), [DsToken](https://github.com/dapphub/ds-token.git), [Uniswap](https://github.com/Uniswap/uniswap-v2-core.git), [SkinCoin](https://github.com/Steamtradenet/smart-contract.git), [0xMonorepo](https://github.com/0xProject/0x-monorepo.git), [Minime](https://github.com/Giveth/minime.git), [Klenergy](https://github.com/klenergy/ethereum-contracts.git), [Digixdao](https://github.com/DigixGlobal/digixdao-contracts.git), [Openzeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts).

**ERC1155**

The  ERC1155  standard  provides  an  interface  for  managing  anycombination of fungible and non-fungible tokens in a single contract efficiently. The standard was created in order to promote a better integration between the ERC20 and ERC721 standards, so with the ERC1155 token can perform the same functions as that the aforementioned tokens, improving the functionality of both and avoiding implementation errors. We selected 4 ERC20 open repositories to run the experiment.


[0xSequence](https://github.com/0xsequence/erc-1155), [Openzeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts), [Enjin](https://github.com/enjin/erc-1155), [Decentralized Stock Market](https://github.com/esdras-santos/decentralized_stock_market_ERC1155).


**ERC3156**

The ERC3156 standard is composed by ERC3156FlashBorrower and ERC3156FlashLender interfaces and together they provide a standardization for single-asset flash loans. We selected 5 ERC3156 open repositories to run the experiment.


[ArgoBytes](https://github.com/SatoshiAndKin/argobytes-contracts.git), [Dss Flash](https://github.com/hexonaut/dss-flash.git), [Erc3156](https://github.com/fifikobayashi/ERC3156.git), [Wrappes](https://github.com/albertocuestacanada/ERC3156-Wrappers.git), [Weth10](https://github.com/WETH10/WETH10.git).

**Experiment**


In order to reproduce all experiments described in the paper you should have the [golang environment installed](https://towardsdev.com/golang-tutorial-2-installing-golang-on-linux-windows-and-mac-os-debf823eb699) and [docker](https://docs.docker.com/engine/install/).
Then you should build the solc-verify image in the Dockerfile-solcverify.src file and write the repository file path in searchDir variable on the main.go script. Finally you should execute the go run main.go command. The experiments will be processed and the results exported to a .csv spreadsheet.



## Verify contracts

In order to build the docker container and verify the smart contracts in this repository. Please follow the instructions presented in [solc-verify](https://github.com/SRI-CSL/solidity/blob/boogie/docker/README.md) github page.


## Running The Verification Tool


This Docker allows us to quickly run the Verification Tool.
To build the tool in a docker container you should clone the project and in the tool directory run the the following command:

```
docker-compose up --build tool
```

The tool can be accessed through the link: http://localhost:3000/#/

