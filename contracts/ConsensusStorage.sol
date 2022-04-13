pragma solidity 0.8.10;


contract ConsensusStorage {
    uint256 public blockLimit;
    uint256 public gasPrice;
    address public rewardPool;
    bool public isPermissioned;
}
