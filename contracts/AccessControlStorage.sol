pragma solidity 0.8.10;

contract SwimmerNetworkACStorage {
    // keccak256("VALIDATOR")
    bytes32 public constant VALIDATOR_ROLE = 0xa95257aebefccffaada4758f028bce81ea992693be70592f620c4c9a0d9e715a;
    // keccak256("ADD_REMOVE_FROM_TO_LIST")
    bytes32 public constant SETBLACKLIST_ROLE = 0x9bde475dbc9562d35d651158f5bc742cb59c702bf2c1e4baf1387dc476ea04bd;

    mapping (address => uint256) public blockedTime;

    uint256 public firstBanningTime;
    uint256 public secondBanningTime;

    mapping (address => bool) public feeCoverInfo;
    address[] public validatorsSet;
    uint public numberOfActiveValidators;
    mapping (address => mapping (address => bool)) public WhitelistedAddresses;
    mapping (address => mapping (bytes4 => bool)) public WhitelistedFunctionSigs;
}