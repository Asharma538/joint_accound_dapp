// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract JointAccountDApp {
    struct User {
        uint id;
        string name;
        uint balance;
    }

    struct JointAccount {
        uint balance;
        bool isInitialized;
    }

    struct Queue {
        uint[] elements; // Array to hold the queue elements
        uint head;       // Points to the front of the queue
        uint tail;       // Points to the next available position in the queue
    }

    mapping(uint => User) public users; // userId to User struct
    mapping(uint => mapping(uint => JointAccount)) public jointAccounts; // Mapping between userIds to JointAccount
    mapping(uint => bool) public registeredUsers; // Check if user is registered

    uint public userCount;
    Queue private queue; // Declare a queue as a state variable
    address public owner;

    event UserRegistered(uint id, string name); 
    event AccountCreated(uint user1, uint user2);
    event AmountTransferred(uint sender, uint receiver, uint amount);
    event AccountClosed(uint user1, uint user2);
    event FundsAssigned(uint indexed userId1, uint indexed userId2, uint amount1, uint amount2);

    constructor() {
        owner = msg.sender; // Contract owner is the one who deployed the contract
    }

    // Function to register a user
    function registerUser(uint _id, string memory _name) public {
        require(!registeredUsers[_id], "User is already registered.");
        users[_id] = User(_id, _name, 0);
        registeredUsers[_id] = true;
        userCount++;
        emit UserRegistered(_id, _name);
    }

    
    // Create a joint account between two users
    function createJointAccount(uint _userId1, uint _userId2) public {
        require(registeredUsers[_userId1] && registeredUsers[_userId2], "Both users must be registered.");
        require(!jointAccounts[_userId1][_userId2].isInitialized, "Account already exists between users.");

        // Initialize the joint account by setting balance and isInitialized
        jointAccounts[_userId1][_userId2].balance = 0;
        jointAccounts[_userId1][_userId2].isInitialized = true;

        // You can optionally initialize the reverse direction (_userId2 -> _userId1) if needed
        jointAccounts[_userId2][_userId1].balance = 0;
        jointAccounts[_userId2][_userId1].isInitialized = true;

        emit AccountCreated(_userId1, _userId2);
    }

    // Function to assign money to the joint account (only by owner)
    function assignFunds(uint _userId1, uint _userId2, uint _amount1,uint _amount2) public onlyOwner {
        require(registeredUsers[_userId1] && registeredUsers[_userId2], "Both users must be registered.");
        require(jointAccounts[_userId1][_userId2].isInitialized, "Joint account does not exist.");

        // Assign funds to the joint account
        jointAccounts[_userId1][_userId2].balance += _amount1;
        jointAccounts[_userId2][_userId1].balance += _amount2; // Update both directions

        emit FundsAssigned(_userId1, _userId2, _amount1,_amount2);
    }

    // Modifier to restrict access to the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner.");
        _;
    }

    // Utility functions for the queue
    function enqueue(uint value) internal {
        queue.elements.push(value); // Add the element to the end
        queue.tail++;
    }

    function dequeue() internal returns (uint) {
        require(queue.head < queue.tail, "Queue is empty");
        uint value = queue.elements[queue.head]; // Get the first element
        queue.head++; // Move the head pointer
        return value;
    }

    function isEmpty() internal view returns (bool) {
        return queue.head == queue.tail;
    }

    // For making the queue empty
    function makeQueueEmpty() internal {
        while(!isEmpty()){
            dequeue();
        }
    }

    // Send amount between users with path support
    function sendAmount(uint _senderId, uint _receiverId, uint _amount) public {
        require(registeredUsers[_senderId] && registeredUsers[_receiverId], "Both users must be registered.");
        
        // Find a path from sender to receiver
        uint[] memory path = findPath(_senderId, _receiverId);
        require(path.length > 0, "No path exists between users.");

        // Transfer amounts along the path
        for (uint i = 0; i < path.length - 1; i++) {
            require(jointAccounts[path[i]][path[i + 1]].balance >= _amount, "Insufficient balance along the path.");
            jointAccounts[path[i]][path[i + 1]].balance -= _amount;
            jointAccounts[path[i + 1]][path[i]].balance += _amount;
        }
        
        emit AmountTransferred(_senderId, _receiverId, _amount);
    }

    // Find a path between two users using BFS
    function findPath(uint _startId, uint _endId) internal returns (uint[] memory) {
        makeQueueEmpty();
        enqueue(_startId); // Start BFS from the starting user
        bool[] memory visited = new bool[](userCount);
        uint[] memory previous = new uint[](userCount); // Store previous nodes for path reconstruction
        visited[_startId] = true;

        while (!isEmpty()) {
            uint current = dequeue();

            // If we reached the end user, build the path
            if (current == _endId) {
                return buildPath(previous, _startId, _endId);
            }

            // Explore all adjacent users (joint accounts)
            for (uint i = 0; i < userCount; i++) {
                if (jointAccounts[current][i].balance > 0 && !visited[i]) { // Check if there's an account
                    enqueue(i); // Add to queue
                    visited[i] = true;
                    previous[i] = current; // Track the path
                }
            }
        }

        return new uint[](0) ; // Return an empty array if no path found
    }

    // Build the path from the previous nodes tracked
    function buildPath(uint[] memory previous, uint _startId, uint _endId) internal view returns (uint[] memory) {
        uint[] memory path = new uint[](userCount);
        uint count = 0;
        uint current = _endId;

        while (current != _startId) {
            path[count] = current;
            count++;
            current = previous[current];
        }
        path[count] = _startId;
        count++;

        // Reverse the path array
        uint[] memory finalPath = new uint[](count);
        for (uint i = 0; i < count; i++) {
            finalPath[i] = path[count - 1 - i];
        }

        return finalPath;
    }

    // Close a joint account between two users
    function closeAccount(uint _userId1, uint _userId2) public {
        require(jointAccounts[_userId1][_userId2].isInitialized, "No account exists between users.");
        
        // Manually remove entries in the mapping
        delete jointAccounts[_userId1][_userId2];
        delete jointAccounts[_userId2][_userId1];
        emit AccountClosed(_userId1, _userId2);
    }

    // Utility to get joint account balance between two users
    function getJointAccountBalance(uint _userId1, uint _userId2) public view returns (uint) {
        require(registeredUsers[_userId1] && registeredUsers[_userId2], "Both users must be registered.");
        return jointAccounts[_userId1][_userId2].balance + jointAccounts[_userId2][_userId1].balance;
    }
}
