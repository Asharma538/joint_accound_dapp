from solcx import install_solc, set_solc_version, compile_standard
from web3 import Web3
import random
import numpy as np
import time
from matplotlib import pyplot as plt

# Geth process address
geth_process_address = "http://127.0.0.1:8545"
w3 = Web3(Web3.HTTPProvider(geth_process_address))
num_users = num_nodes = 100

def init_env():
    # Initialize Solidity compiler version
    sol_version = "0.8.24"
    install_solc(sol_version)
    set_solc_version(sol_version)

def deploy_smart_contract():
    # Read the Solidity contract file
    with open("./A.sol", "r") as file:
        jointAccountDAppFile = file.read()

    # Compile the Solidity contract
    compiled_sol = compile_standard({
        "language": "Solidity",
        "sources": {
            "A.sol": {
                "content": jointAccountDAppFile
            }
        },
        "settings": {
            "outputSelection": {
                "*": {
                    "*": ["abi", "metadata", "evm.bytecode", "evm.sourceMap"]
                }
            }
        }
    })

    # Extract bytecode and ABI
    contract_bytecode = compiled_sol['contracts']['A.sol']['JointAccountDApp']['evm']['bytecode']['object']
    contract_abi = compiled_sol['contracts']['A.sol']['JointAccountDApp']['abi']

    # Set default account
    if w3.eth.accounts:
        w3.eth.defaultAccount = w3.eth.accounts[0]
    else:
        raise Exception("No accounts available")

    # Deploy the contract
    JointAccountDApp = w3.eth.contract(abi=contract_abi, bytecode=contract_bytecode)
    transaction_hash = JointAccountDApp.constructor().transact({
        'from': w3.eth.defaultAccount,
        'gasPrice': w3.to_wei('50', 'gwei'),
        'gas': 3000000
    })

    # Wait for the transaction receipt
    tx_receipt = w3.eth.wait_for_transaction_receipt(transaction_hash)
    print(f"Contract deployed at address: {tx_receipt.contractAddress}")
    return tx_receipt.contractAddress, contract_abi

def get_contract_instance(addr, abi):
    # Get the contract instance
    contract_instance = w3.eth.contract(address=addr, abi=abi)
    return contract_instance

# Initialize environment and deploy the smart contract
init_env()
contract_address, contract_abi = deploy_smart_contract()
contract_instance = get_contract_instance(contract_address, contract_abi)

def register_users():
    # Register users in the smart contract
    transaction_hash = None
    for i in range(num_users):
        transaction_hash = contract_instance.functions.registerUser(i, "user" + str(i)).transact({'from': w3.eth.defaultAccount})
        print("Registered user", i, "as user" + str(i))

    # Wait for the last transaction receipt
    w3.eth.wait_for_transaction_receipt(transaction_hash)
    user_count = contract_instance.functions.userCount().call()
    print("Total users registered:", user_count)
    print("=" * 50)

def create_joint_accounts():
    # Create joint accounts between users
    transaction_hash = None
    node_connections = {}
    for i in range(num_nodes):
        node_connections[i] = set()

    # Making a connected graph of joint accounts
    for i in range(num_users):
        try:
            transaction_hash = contract_instance.functions.createJointAccount(i, (i + 1) % num_users).transact({'from': w3.eth.defaultAccount})
            node_connections[i].add((i + 1) % num_users)
            node_connections[(i + 1) % num_users].add(i)
            print(f"Created Account between user{i} and user{(i + 1) % num_users}")
        except Exception as e:
            print(f"Error creating joint account between user{i} and user{(i + 1) % num_users}: {e}")

    # Generating degrees following the power-law distribution
    degrees = np.random.zipf(3, num_users)
    degrees = np.clip(degrees, 1, 10)

    for i in range(num_users):
        possible_connections = list(set(range(num_users)) - {i} - node_connections[i])
        connections_to_add = degrees[i] - len(node_connections[i])

        if connections_to_add > 0 and possible_connections:
            connections = random.sample(possible_connections, min(len(possible_connections), connections_to_add))
            for connection in connections:
                try:
                    transaction_hash = contract_instance.functions.createJointAccount(i, connection).transact({'from': w3.eth.defaultAccount})
                    node_connections[i].add(connection)
                    node_connections[connection].add(i)
                    print(f"Created Account between user{i} and user{connection}")
                except Exception as e:
                    print(f"Error creating joint account between user{i} and user{connection}: {e}")

    # Wait for the last transaction receipt
    w3.eth.wait_for_transaction_receipt(transaction_hash)
    print("Joint account creation completed")
    print("=" * 50)
    return node_connections

def assign_funds(node_connections):
    # Assign funds to joint accounts
    mean_balance = 10
    for user1, connections in node_connections.items():
        for user2 in connections:
            balance = np.random.exponential(mean_balance)
            transaction_hash = contract_instance.functions.assignFunds(user1, user2, int(balance / 2), int(balance / 2)).transact({'from': w3.eth.defaultAccount})
            print(f"Assigned {balance} to joint account between user{user1} and user{user2} equally")
            w3.eth.wait_for_transaction_receipt(transaction_hash)
    print("Fund assignment completed")
    print("=" * 50)

def fire_transactions_analyse_success_rate(n_transactions, node_connections):
    # Fire transactions and analyze success rate
    success_count = 0
    fail_count = 0
    success_ratios = []

    for i in range(n_transactions):
        user1 = random.choice(list(node_connections.keys()))
        user2 = random.choice(list(node_connections[user1]))

        try:
            contract_instance.functions.sendAmount(user1, user2, 1).transact({'from': w3.eth.defaultAccount})
            success_count += 1
        except Exception as e:
            fail_count += 1

        if (i + 1) % 100 == 0:
            success_ratios.append(success_count / (success_count + fail_count))
            print(f"Success ratio after {i + 1} transactions: {success_ratios[-1]}")

    transactions = range(100, n_transactions + 100, 100)
    plt.figure(figsize=(10, 6))
    plt.plot(transactions, success_ratios)
    plt.xlabel("Number of Transactions", fontsize=10)
    plt.ylabel("Success Ratio", fontsize=10)
    plt.title("Transaction Success Ratio Over Time", fontsize=14)
    plt.grid(True)

    plt.savefig("transactions_success_rates"+str(n_transactions)+".png")
    plt.show()

# Register users, create joint accounts, assign funds, and analyze transaction success rate
register_users()
node_connections = create_joint_accounts()
assign_funds(node_connections)
fire_transactions_analyse_success_rate(1000, node_connections)