// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract JointAccounts { // Very simple smart contract that allows users to create a "Joint Account" with another user. Both users can deposit/withdrawal from the same account.

    uint public total_accounts; // Keeps track of the amount of joint accounts created.
    
    mapping(address => uint) private user_to_account; // Returns the "joint account ID" from a users address.
    
    mapping(uint => uint) private account_to_balance; // Returns the balance in WEI from an "joint account ID".
    
    // Uses the 'user_to_account' mapping to make a modifier that checks if the function caller has been assigned to a joint account yet.
    modifier hasAccount { 
        require(user_to_account[msg.sender] != 0, "You must create a Joint Account first!");
        _;
    }
    
    // First function every user will use. You specify the second user (etheruem address), and send at least 0.01 ETH. 
    function start_joint_account(address payable _secondUser) payable public {
        require(user_to_account[msg.sender] == 0, "You may only have one Joint Account per address.");
        require(user_to_account[_secondUser] == 0, "The second user is already part of a Joint Account.");
        require(_secondUser != msg.sender, "The second user cannot be yourself.");
        require(msg.value >= 10000000000000000, "Must deposit at least 0.01 eth, to start an Joint Account.");
        uint id = total_accounts + 1; // Gets the ID for the users new joint account by checking how many total accounts exist, then adding 1.
        total_accounts += 1; // Adds 1 to the 'total_accounts' variable. This happens so the contract can keep track of how many joint accounts exist.
        user_to_account[msg.sender] = id; // Assigns the function callers etheruem address to the new Joint Account ID. 
        user_to_account[_secondUser] = id; // Assigns the second users etheruem address to the new Joint Account ID.
        account_to_balance[id] = uint(msg.value); // Sets the 'balance' of the new joint account to the amount of ETH sent. (in WEI)
    }
    
    // Function that lets the caller deposit any amount of ETH.
    function deposit() payable public hasAccount {
        account_to_balance[user_to_account[msg.sender]] += msg.value; // Adds the ammount deposited (in WEI) to the Joint Account the user is in.
    }
    
    // Lets the caller withdrawal any amount of ETH (in WEI), as long as the ETH is in their account.
    function withdrawal(uint _weiTowithdrawal) public hasAccount {
        uint user_balance = account_to_balance[user_to_account[msg.sender]]; // Gets the balance of the function caller and assigns it to a variable.
        require(_weiTowithdrawal <= user_balance); // Makes sure that the function callers joint account has enough funds to allow a withdrawal.
        account_to_balance[user_to_account[msg.sender]] -= _weiTowithdrawal; // Subtracts the ETH sent (in WEI) from the function callers joint account balance.
        payable(msg.sender).transfer(_weiTowithdrawal); // Sends the function caller the ETH amount requested, completing the withdrawal.
    }
    
    // Allows a user to add another user via their etheruem address, to their joint account.
    function add_user(address payable _userAddress) public {
        require(user_to_account[_userAddress] == 0, "User cannot have a Joint Account already.");
        uint id = user_to_account[msg.sender]; // Copies the ID of the function callers joint account, for use in the next line.
        user_to_account[_userAddress] = id; // This adds the new user to the function callers joint account.
    }
    
    function view_balance(address _addy) view public returns(uint) {
        return account_to_balance[user_to_account[_addy]]; // Gets the balance of a joint account from the etheruem address provided.
    }
}