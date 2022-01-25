pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./AccessControlStorage.sol";


contract SwimmerNetworkAC is AccessControl, Initializable, SwimmerNetworkACStorage{
    function initialize(address[] memory admins) external initializer() {
        CREATE_CONTRACT_ROLE = keccak256("CREATE_CONTRACT");
        VALIDATOR_ROLE = keccak256("VALIDATOR");
        SETBLACKLIST_ROLE = keccak256("ADD_REMOVE_FROM_TO_LIST");
        firstBanningTime = 1 hours;
        secondBanningTime = 7955107200; // 2222/Feb/02 00:00:00
        for(uint i = 0; i < admins.length; i++){
            _grantRole(CREATE_CONTRACT_ROLE, admins[i]);
            _grantRole(VALIDATOR_ROLE, admins[i]);
            _grantRole(SETBLACKLIST_ROLE, admins[i]);
            _grantRole(DEFAULT_ADMIN_ROLE, admins[i]);
        }
    }

    function setBlacklist(address add) external onlyRole(SETBLACKLIST_ROLE){
        require(blockedTime[add] != secondBanningTime, "Permanently BAN");
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
        return blockedTime[add] > block.timestamp;
    }
}
