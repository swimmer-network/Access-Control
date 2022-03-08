
pragma solidity 0.8.10;

contract StakingStorage {
    address public CRAToken;
    uint public minStakedAmount;
    uint public maxStakedAmount;
    uint public unstakedEpoch; // wait for a certain period to withdraw stake
    // uint256 public startTime;

    struct Validator {
        uint stakedAmount;
        uint lastStartUnstaking; // user can only withdraw stake after unstakedEpoch (21) days
        uint unstakingAmount;
    }

    mapping (address => Validator) public validatorInfo;

}