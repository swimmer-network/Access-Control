pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./AccessControlStorage.sol";


contract SwimmerNetworkAC is AccessControl, Initializable, SwimmerNetworkACStorage{
    function initialize(address[] memory admins) external initializer() {
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
