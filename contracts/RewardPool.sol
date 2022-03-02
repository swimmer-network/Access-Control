pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./interface/IAccessControl.sol";
import "./RewardPoolStorage.sol";


contract RewardPool is Ownable, Initializable, RewardPoolStorage{
    function initialize(address _owner, address _rewardToken, address _accessControl, uint _burnRate) external initializer() {
        rewardToken = _rewardToken;
        accessControlAddress = _accessControl;
        burnRate = _burnRate;
        _transferOwnership(_owner);
    }

    function addValidatorsStake(address[] memory validators, uint[] memory amounts) external onlyOwner(){
        require(validators.length == amounts.length, "invalid length");
        uint _total = totalStake;
        for(uint i = 0; i < validators.length; i++){
            if(validators[i] != address(0x0) && IAccessControl(accessControlAddress).isValidator(validators[i])){
                stakedAmounts[validators[i]] += amounts[i];
                _total += amounts[i];
            }
        }
        totalStake = _total;
    }

    function reduceValidatorsStake(address[] memory validators, uint[] memory amounts) external onlyOwner(){
        require(validators.length == amounts.length, "invalid length");
        uint _total = totalStake;
        for(uint i = 0; i < validators.length; i++){
            if(validators[i] != address(0x0) && IAccessControl(accessControlAddress).isValidator(validators[i])){
                require(stakedAmounts[validators[i]] >= amounts[i], "inefficient staked amount");
                stakedAmounts[validators[i]] -= amounts[i];
                _total -= amounts[i];
            }
        }
        totalStake = _total;
    }

    function claimReward() external{
        require(lastClaimedTime + claimedPeriod < block.timestamp, "RewardPool: not allow to claim");
        uint currentRewardBalance = IERC20(rewardToken).balanceOf(address(this));
        address[] memory validatorsSet = IAccessControl(accessControlAddress).getValidatorsSet();
        uint rewardPerStake = currentRewardBalance * CRAExponent * burnRate / totalStake / rateDecimals;
        for(uint i = 0; i < validatorsSet.length; i++){
            if(validatorsSet[i] != address(0x0) && IAccessControl(accessControlAddress).isValidator(validatorsSet[i])){
                // validator reward
                uint _reward = rewardPerStake * stakedAmounts[validatorsSet[i]] / CRAExponent;
                // transfer reward to validators
                IERC20(rewardToken).transfer(validatorsSet[i], _reward);
            }
        }
        // burn
        IERC20(rewardToken).transfer(address(0x0), IERC20(rewardToken).balanceOf(address(this)));
        lastClaimedTime = block.timestamp;
    }

    function changeClaimPeriod(uint newPeriod) external onlyOwner(){
        claimedPeriod = newPeriod;
    }

    function balanceOfStake(address validator) external view returns(uint256){
        return stakedAmounts[validator];
    }
}
