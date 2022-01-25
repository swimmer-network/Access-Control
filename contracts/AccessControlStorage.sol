pragma solidity 0.8.10;

contract SwimmerNetworkACStorage {
    bytes32 public CREATE_CONTRACT_ROLE = keccak256("CREATE_CONTRACT");
    bytes32 public VALIDATOR_ROLE = keccak256("VALIDATOR");
    bytes32 public SETBLACKLIST_ROLE = keccak256("ADD_REMOVE_FROM_TO_LIST");

    mapping (address => uint256) public blockedTime;


    uint256 public firstBanningTime;
    uint256 public secondBanningTime;
}