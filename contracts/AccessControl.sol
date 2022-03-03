pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./AccessControlStorage.sol";
import "./interface/IOwnable.sol";


contract SwimmerNetworkAC is AccessControl, Initializable, SwimmerNetworkACStorage{
    event SetFeeCover(address _contract, address owner, bool onoff);
    event SetBlacklist(address add, uint banningTime);
    event RemoveBlacklist(address add);

    function initialize(address[] memory admins) external initializer() {
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
        emit SetBlacklist(add, blockedTime[add]);
    }
    function removeBlacklist(address add) external onlyRole(SETBLACKLIST_ROLE){
        blockedTime[add] = 0;
        emit RemoveBlacklist(add);
    }

    function isBlacklist(address add) external view returns(bool){
        return blockedTime[add] > block.timestamp;
    }

    function setFeeCover(address _contract, bool onoff) external onlyRole(CREATE_CONTRACT_ROLE){
        ContractInfo storage info = feeCoverInfo[_contract];
        if(info.owner == address(0x0)){
            require(IOwnable(_contract).owner() == _msgSender(), "not contract owner");
            info.owner = _msgSender();
        }
        else{
            require(info.owner == _msgSender(), "Invalid owner");
        }
        info.feeCover = onoff;
        emit SetFeeCover(_contract, _msgSender(), onoff);
    }

    function addValidators(address[] memory validators) external onlyRole(DEFAULT_ADMIN_ROLE){
        require(validators.length > 0, "validators are empty");
        for(uint i = 0; i < validators.length; i++){
            validatorsSet.push(validators[i]);
            _grantRole(VALIDATOR_ROLE, validators[i]);
            numberOfActiveValidators += 1;
        }
    }

    function removeValidators(uint[] memory indexes) external onlyRole(DEFAULT_ADMIN_ROLE){
        require(indexes.length > 0, "validators are empty");
        for(uint i = 0; i < indexes.length; i++){
            delete validatorsSet[indexes[i]];
            _revokeRole(VALIDATOR_ROLE, validatorsSet[indexes[i]]);
            numberOfActiveValidators -= 1;
        }
    }
    
    function getValidatorsSet() external view returns(address[] memory){
        return validatorsSet;
    }

    function isValidator(address add) external view returns(bool){
        return hasRole(VALIDATOR_ROLE, add);
    }
}
