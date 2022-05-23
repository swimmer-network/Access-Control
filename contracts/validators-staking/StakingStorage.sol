
pragma solidity 0.8.10;

contract StakingStorage {
    address public CRAToken;
    uint public minStakedAmount;
    uint public maxStakedAmount;
    uint public unstakedEpoch; // wait for a certain period to withdraw stake
    uint public slippage; // after endtime + slippage, validators donot withdraw stakes will keep staking
    uint public constant day = 86400; // 1 day = 86400s
    mapping(address => bool) public whitelist;

    struct Validator {
        uint stakedAmount;
        uint depositTime; // user can only withdraw stake after unstakedEpoch (28) days
    }

    mapping (address => Validator) public validatorInfo;

    uint public totalStake;

}