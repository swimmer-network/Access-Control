pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract SwimmerNetworkAC is AccessControl{
    bytes32 public constant CREATE_CONTRACT_ROLE = keccak256("CREATE_CONTRACT");
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR");
    bytes32 public constant SETBLACKLIST_ROLE = keccak256("ADD_REMOVE_FROM_TO_LIST");

    mapping (address => uint256) public blockedTime;


    uint256 public firstBanningTime = 1 hours;
    uint256 public secondBanningTime = 7955107200; // 2222/Feb/02 00:00:00

    constructor(address[] memory admins) public {
        for(uint i = 0; i < admins.length; i++){
            _grantRole(CREATE_CONTRACT_ROLE, admins[i]);
            _grantRole(VALIDATOR_ROLE, admins[i]);
            _grantRole(SETBLACKLIST_ROLE, admins[i]);
            _grantRole(DEFAULT_ADMIN_ROLE, admins[i]);
        }
    }

    function setBlacklist(address add) external onlyRole(SETBLACKLIST_ROLE){
        if(blockedTime[add] == 0){
            blockedTime[add] = block.timestamp + firstBanningTime;
        }
        else{
            blockedTime[add] = secondBanningTime;
        }
    }

    function removeBlacklist(address add) external onlyRole(SETBLACKLIST_ROLE){
            blockedTime[add] = 0;
    }

    function isBlacklist(address add) external view returns(bool){
        return blockedTime[add] < block.timestamp;
        if(blockedTime[add] == 0) {
            return false;
        }
        if(blockedTime[add] == secondBanningTime){
            return true;
        }
        if(blockedTime[add] > block.timestamp){
            return true;
        }
        else{
            return false;
        }
    }
}
