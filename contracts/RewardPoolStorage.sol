pragma solidity 0.8.10;

contract RewardPoolStorage {
    mapping(address => uint256) public stakedAmounts;
    uint256 public totalStake;
    address public rewardToken;
    address public accessControlAddress;
    uint256 public burnRate;
    uint256 public lastClaimedTime;
    uint256 public claimedPeriod;
    uint256 public constant rateDecimals = 10**4;
    uint256 public constant CRAExponent = 10**12;
}
