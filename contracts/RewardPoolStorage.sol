pragma solidity 0.8.10;

contract RewardPoolStorage {
    address public rewardToken;
    address public accessControlAddress;
    mapping(address => uint256) balanceOfWork;
    uint256 public lastClaimedTime;
    uint256 public claimedPeriod;
}
