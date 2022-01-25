pragma solidity 0.8.10;

contract SwimmerNetworkACStorage {
    bytes32 public CREATE_CONTRACT_ROLE;
    bytes32 public VALIDATOR_ROLE ;
    bytes32 public SETBLACKLIST_ROLE;

    mapping (address => uint256) public blockedTime;


    uint256 public firstBanningTime;
    uint256 public secondBanningTime;
}