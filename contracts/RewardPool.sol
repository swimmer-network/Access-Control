pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./interface/IAccessControl.sol";
import "./interface/ITokenBurn.sol";
import "./RewardPoolStorage.sol";


contract RewardPool is Ownable, Initializable, RewardPoolStorage{
    function initialize(address _owner, address _accessControl, uint _burnRate, uint minimum, uint maximum, uint baseRate)
        external initializer() {
        // rewardToken = _rewardToken;
        accessControlAddress = _accessControl;
        burnRate = _burnRate;
        minimumStake = minimum;
        maximumStake = maximum;
        baseRewardRate = baseRate;
        // claimedPeriod = 14 * 24 * 3600;
        _transferOwnership(_owner);
    }

    function addValidatorsStake(address[] memory validators, uint[] memory amounts) external onlyOwner(){
        require(validators.length == amounts.length, "invalid length");
        uint _total = totalStake;
        for(uint i = 0; i < validators.length; i++){
            if(validators[i] != address(0x0) && IAccessControl(accessControlAddress).isValidator(validators[i])){
                require(amounts[i] >= minimumStake, "must be greater than minimum");
                require(amounts[i] <= maximumStake, "must be less than maximum");

                stakedAmounts[validators[i]] = amounts[i];
                _total += amounts[i];
            }
        }
        totalStake = _total;
    }

    function updateValidatorsStake(address[] memory validators, uint[] memory amounts) external onlyOwner(){
        require(validators.length == amounts.length, "invalid length");
        uint _total = totalStake;
        for(uint i = 0; i < validators.length; i++){
            if(validators[i] != address(0x0) && IAccessControl(accessControlAddress).isValidator(validators[i])){
                require(stakedAmounts[validators[i]] + amounts[i] < maximumStake, "must be less than maximum");
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
        if(lastClaimedTime == 0){
            lastClaimedTime = block.timestamp;
        }
        else{
            require(lastClaimedTime < block.timestamp, "RewardPool: not allow to claim");
        }
        address[] memory validatorsSet = IAccessControl(accessControlAddress).getValidatorsSet();
        (uint burnAmount, uint remainingReward, uint baseRewardPerValidator, uint activeNumber) = _calculateBaseReward();
        uint remainingStake = totalStake - minimumStake * activeNumber;
        // validator base reward
        uint _reward = baseRewardPerValidator / CRAExponent;
        for(uint i = 0; i < validatorsSet.length; i++){
            if(validatorsSet[i] != address(0x0) && IAccessControl(accessControlAddress).isValidator(validatorsSet[i])){
                // if stake more than minimum
                if(stakedAmounts[validatorsSet[i]] > minimumStake){
                    uint _r = (stakedAmounts[validatorsSet[i]] - minimumStake) * remainingReward / remainingStake / CRAExponent;
                    payable(validatorsSet[i]).transfer(_reward + _r);
                } else {
                    // transfer base reward to validators
                    payable(validatorsSet[i]).transfer(_reward);

                }
            }
        }
        // burn
        if(burnAmount > 0){
            payable(address(0x0)).transfer(burnAmount);
        }
        lastClaimedTime = lastClaimedTime + claimedPeriod;
    }

    function changeClaimPeriod(uint newPeriod) external onlyOwner(){
        claimedPeriod = newPeriod;
    }

    function balanceOfStake(address validator) external view returns(uint256){
        return stakedAmounts[validator];
    }

    function _calculateBaseReward() internal view returns(uint,uint,uint,uint){
        uint currentRewardBalance = address(this).balance;
        uint activeNumber = IAccessControl(accessControlAddress).numberOfActiveValidators();
        uint rewardAfterBurn = currentRewardBalance * CRAExponent * (rateDecimals - burnRate) / rateDecimals;
        uint totalBaseReward = rewardAfterBurn * baseRewardRate / rateDecimals;
        uint remainingReward = rewardAfterBurn - totalBaseReward;
        uint baseRewardPerValidator = totalBaseReward / activeNumber;
        uint burnAmount = currentRewardBalance - rewardAfterBurn/CRAExponent;
        return (burnAmount, remainingReward, baseRewardPerValidator, activeNumber);
    }

    function changeMinimumThreshold(uint newThreshold) external onlyOwner(){
        require(newThreshold > 0, "must be greater than 0");
        minimumStake = newThreshold;
    }

    function changeMaximumThreshold(uint newThreshold) external onlyOwner(){
        require(newThreshold > minimumStake, "must be greater than minimum");
        maximumStake = newThreshold;
    }
    fallback() external payable {
        
    }
}