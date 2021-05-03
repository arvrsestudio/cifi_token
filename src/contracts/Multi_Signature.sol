// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Cifi_Token.sol";

contract Multi_Signature{
    
    // The addresses to form group of authority
    mapping(address => bool) public owners;
    
    //Total count of transactions
    uint transactionIdx;
    uint[] public pendingTransactions;
    
    //type of transactions
    enum TransactionType{MINT,BURN,REMOVE_OWNER}
    
    // Map to fetch transactino from transaction ID
    mapping(uint => Transaction) public transactions;
    
    //Minimum signatures required and max owners 
    uint8 constant public signRequiredCount = 3;
    uint8 constant public maxOwnerCount = 5;
    uint8 public curOwnerCount;

    // structure of a Transaction
    struct Transaction {
      address from;
      TransactionType tType;
      uint amount;
      uint8 signatureCount;
      mapping (address => bool) signatures;
      address dataAddress;
    }

    //modifiers 
    
    modifier validOwner() {
        require(owners[msg.sender], " Not a valid owner ");
        _;
    }
    
    // Events 
    event transactionInitiated(uint transactionId, TransactionType _type);
    event transactionSigned(address authority,uint transactionId);
    event transactionDeleted(uint transactionId);
    
    //integrate cifitoken contract here 
    Cifi_Token cifiTokenContract = Cifi_Token(0xd7B63981A38ACEB507354DF5b51945bacbe28414);
    
    constructor() {
        owners[msg.sender]=true;
        curOwnerCount++;
    }
    
    //function to return the active transaction ids
    function getActiveTransactions()
      validOwner
      view
      public
      returns (uint[] memory _transactions) {
      return pendingTransactions;
    }
    
    // function to get count of pending transactions
    function getPendingTransactionLength()
      public
      view
      returns (uint _length) {
      return pendingTransactions.length;
    }
    
    //function to add owner/authority
    function addOwner(address owner)
        validOwner
        public {
        require(owners[owner]!=true,"Already an owner.");
        require(curOwnerCount<maxOwnerCount,"Can't add more than 5 Authorities");
        owners[owner] = true;
        curOwnerCount++;
    }

    // functions to initiate transaction 
    function initRemoveOwner(address _oldOwner)
        validOwner
        public {
            require(owners[_oldOwner], " Not a valid owner in input");
            require(curOwnerCount>=(maxOwnerCount-1), "Owner count is already less then needed.");
            transactionIdx++;
            uint transactionId = transactionIdx;
            transactions[transactionId].from = msg.sender;
            transactions[transactionId].dataAddress=_oldOwner;
            transactions[transactionId].signatureCount=0;
            transactions[transactionId].tType=TransactionType.REMOVE_OWNER;
            pendingTransactions.push(transactionId);
            emit transactionInitiated(transactionId, transactions[transactionId].tType);
    }
    
    function initMint(uint amount, address recipient)
        validOwner
        public {
            transactionIdx++;
            uint transactionId = transactionIdx;
            transactions[transactionId].from = msg.sender;
            transactions[transactionId].tType=TransactionType.MINT;
            transactions[transactionId].amount=amount;
            transactions[transactionId].dataAddress = recipient;
            transactions[transactionId].signatureCount=0;
            pendingTransactions.push(transactionId);
            emit transactionInitiated(transactionId, transactions[transactionId].tType);
    }
    function initBurn(uint amount)
        validOwner
        public {
            transactionIdx++;
            uint transactionId = transactionIdx;
            transactions[transactionId].from = msg.sender;
            transactions[transactionId].tType=TransactionType.BURN;
            transactions[transactionId].amount=amount;
            transactions[transactionId].signatureCount=0;
            pendingTransactions.push(transactionId);
            emit transactionInitiated(transactionId, transactions[transactionId].tType);
    }
    
    // function used for signing a transaction
    function signTransaction(uint transactionId)
      validOwner
      public {
      // Transaction must exist
      require(transactions[transactionId].from !=address(0),"Transaction does not exist");
      //Creator cannot sign this
      require(msg.sender != transactions[transactionId].from, "Creator cannot sign this transaction");
      // Has not already signed this transaction
      require(!transactions[transactionId].signatures[msg.sender],"authority has already signed this transaction");

      transactions[transactionId].signatures[msg.sender] = true;
      transactions[transactionId].signatureCount++;
      
      emit transactionSigned(msg.sender,transactionId);

      if (transactions[transactionId].signatureCount >= signRequiredCount) {
        
        //add logic to mint/burn or add/remove authority
        if(transactions[transactionId].tType==TransactionType.MINT){
            cifiTokenContract.mint(transactions[transactionId].dataAddress,transactions[transactionId].amount);
        }
        else if(transactions[transactionId].tType==TransactionType.BURN){
            cifiTokenContract.burn(transactions[transactionId].amount);
        }
        else{
            require(curOwnerCount>=4,"The owner count is less then threshold!");
            owners[transactions[transactionId].dataAddress] = false;
            curOwnerCount--;
            deleteTransaction(transactionId);
        }
        
        deleteTransaction(transactionId);
      }
    }
    
    //function to delete transactions once they are executed
    function deleteTransaction(uint transactionId)
      validOwner
      private {
      uint8 replace = 0;
      require(pendingTransactions.length > 0,"No pending transactions found");
      for(uint i = 0; i < pendingTransactions.length; i++) {
          if (1 == replace) {
              pendingTransactions[i-1] = pendingTransactions[i];
          } else if (pendingTransactions[i] == transactionId) {
              replace = 1;
          }
      }
      assert(replace == 1);
      // Created an Overflow
      emit transactionDeleted(transactionId);
      delete pendingTransactions[pendingTransactions.length-1];
      delete transactions[transactionId];
      
      }
    
}