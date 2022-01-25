pragma solidity 0.8.10;

contract SwimmerNetworkACStorage {
    bytes32 public constant CREATE_CONTRACT_ROLE = keccak256("CREATE_CONTRACT");
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR");
    bytes32 public constant SETBLACKLIST_ROLE = keccak256("ADD_REMOVE_FROM_TO_LIST");

    mapping (address => uint256) public blockedTime;


    uint256 public firstBanningTime = 1 hours;
    uint256 public secondBanningTime = 7955107200; // 2222/Feb/02 00:00:00
}