# Blockchain Assignment 2

This project demonstrates how to set up and run a local Ethereum blockchain using Geth and interact with it using a Python script which Deploys a Smart Contract (DApp) related to Joint Accounts as described in the Assignment and then fires the transactions.

## Prerequisites

- [Geth (Go Ethereum)](https://geth.ethereum.org/downloads/)
- [Python 3](https://www.python.org/downloads/)

## Setup

Navigate to the cloned/unzipped directory

### Running Geth

To start a local Ethereum blockchain using Geth, run the following command:

```sh
geth --datadir . --dev --http --http.api eth,web3,net --http.corsdomain "https://remix.ethereum.org"
```

### Running the Python Script

To install the necessary dependencies, run the following command:

```sh
pip install -r requirements.txt
```

### Running the Python Script

To interact with the blockchain using a Python script, run the following command:

```sh
python3 A.py
```

### Project Structure
- `A.py`: The main Python script that interacts with the Ethereum blockchain.
- `A.sol`: The Solidity smart contract source code.
- `requirements.txt`: The list of Python dependencies required for the project.

## Additional Information

- Ensure that Geth node process is running before executing the Python script.
- The Python script `A.py` contains the necessary code to interact with the local Ethereum blockchain following the assignment.

## Functionality of Python Script (`A.py`)
The Python script performs the following tasks:

1. Initialize Environment: Sets up the Solidity compiler.
2. Deploy Smart Contract: Compiles and deploys the Solidity smart contract to the local Ethereum blockchain.
3. Register Users: Registers a specified number of users on the blockchain.
4. Create Joint Accounts: Creates joint accounts between users.
5. Assign Funds: Assigns funds to the joint accounts.
6. Fire Transactions and Analyze Success Rate: Sends transactions between users and analyzes the success rate.

## Additional Information
- Ensure that the Geth node process is running before executing the Python script.
- The Python script A.py contains the necessary code to interact with the local Ethereum blockchain following the assignment.