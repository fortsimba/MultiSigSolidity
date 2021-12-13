pragma solidity ^0.6.6;
//Author: Pranay Yadav
contract multisig{
    address payable main;
    mapping(address => bool) public isOwner;
    address[] public owners;
    uint8 m;
    uint8 n;
    uint8 added;
    uint8 txNum;
    struct transferInfo{
        address payable receiver;
        uint256 amt;
        address sender;
        bool executed;
    }
    mapping(uint8 => transferInfo) public pendingTx;
    mapping(uint8 => mapping(address => bool)) public signatures;
    //constructor
    constructor(uint8 _m, uint8 _n) payable public{
        require(_n>=_m);
        main = msg.sender;
        isOwner[main] = true;
        owners.push(main);
        m = _m;
        n = _n;
        added = 1;
        txNum = 0;
    }
    //functions for receiving ether
    receive() external payable{}
    fallback() external payable{}
    //modifier checks if caller is owner
    modifier checkOwner(){
        require(isOwner[msg.sender]==true);
        _;
    }
    //modifier to check if transaction is already sent
    modifier checkSent(uint8 txid){
        require(pendingTx[txid].executed==false);
        _;
    }
    //modifier to check whether txid exists
    modifier checkTxid(uint8 txn){
        require(txn<txNum);
        _;
    }
    //modifier to check whether specified owners have been added
    modifier checkNumOwner{
        require(added>=n);
        _;
    }
    //viewing function
    function viewBalance() public view returns(uint256){
        return(address(this).balance);
    }
    function viewAddress() public view returns(address){
        return(address(this));
    }
    //function to add owner to multisig
    function addOwner(address _address) public checkOwner{
        require(added<n);
        isOwner[_address] = true;
        owners.push(_address);
        added+=1;
    }
    //function to initiate new transaction
    function initiateTransfer(address payable receiver, uint256 amount) public checkOwner checkNumOwner{
        require(address(this).balance >= amount);
        pendingTx[txNum] = transferInfo(receiver, amount, msg.sender, false);
        txNum+=1;
    }
    //function to sign pending transfer (pass transaction number)
    function signTransfer(uint8 txid) public checkTxid(txid) checkOwner{
        require(address(this).balance >= pendingTx[txid].amt);
        signatures[txid][msg.sender] = true;
    }
    //function to check if there are enough signatures for transaction (pass transaction number)
    function checkSig(uint8 txid) view public returns(bool){
        uint8 count = 0;
        for(uint8 i=0;i<=added;i++){
            if(signatures[txid][owners[i]]){
                count++;
            }
            if(count==m){
                return true;
            }
        }
        return false;
    }
    //function to send transaction
    function executeTx(uint8 txid) public checkSent(txid) checkTxid(txid) checkOwner{
        if(checkSig(txid)){
            pendingTx[txid].receiver.transfer(pendingTx[txid].amt);
            pendingTx[txid].executed = true;
        }
    }
}