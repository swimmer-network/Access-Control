pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./interface/IAccessControl.sol";
import "./interface/ITokenBurn.sol";
import "./RewardPoolStorage.sol";


contract RewardPool is Ownable, Initializable, RewardPoolStorage{
    event ClaimReward(address to, uint256 amount);

    function initialize(
        address _owner,
        address _accessControl,
        uint _burnRate,
        uint minimum,
        uint maximum,
        uint baseRate
    ) external initializer() {
        accessControlAddress = _accessControl;
        burnRate = _burnRate;
        minimumStake = minimum;
        maximumStake = maximum;
        baseRewardRate = baseRate;
        claimedPeriod = 2 weeks;
        _transferOwnership(_owner);
    }

    function addValidatorsStake(address[] memory validators, uint[] memory amounts) external onlyOwner(){
        require(validators.length == amounts.length, "invalid length");
        uint _total = totalStake;
        for(uint i = 0; i < validators.length; i++){
            require(IAccessControl(accessControlAddress).isValidator(validators[i]), "Not validator");
            require(amounts[i] >= minimumStake, "must be greater than minimum");
            require(amounts[i] <= maximumStake, "must be less than maximum");

            stakedAmounts[validators[i]] = amounts[i];
            _total += amounts[i];
        }
        totalStake = _total;
    }

    function updateValidatorsStake(address[] memory validators, uint[] memory amounts) external onlyOwner(){
        require(validators.length == amounts.length, "invalid length");
        uint _total = totalStake;
        for(uint i = 0; i < validators.length; i++){
            require(IAccessControl(accessControlAddress).isValidator(validators[i]), "Not validator");
            require(stakedAmounts[validators[i]] + amounts[i] < maximumStake, "must be less than maximum");

            stakedAmounts[validators[i]] += amounts[i];
            _total += amounts[i];
        }
        totalStake = _total;
    }

    function reduceValidatorsStake(address[] memory validators, uint[] memory amounts) external onlyOwner(){
        require(validators.length == amounts.length, "invalid length");
        uint _total = totalStake;
        for(uint i = 0; i < validators.length; i++){
            require(IAccessControl(accessControlAddress).isValidator(validators[i]), "Not validator");
            require(stakedAmounts[validators[i]] >= amounts[i], "inefficient staked amount");

            stakedAmounts[validators[i]] -= amounts[i];
            _total -= amounts[i];
        }
        totalStake = _total;
    }

    function claimReward() external{
        require(lastClaimedTime > 0 && lastClaimedTime < block.timestamp, "RewardPool: not allow to claim");
        address[] memory validatorsSet = IAccessControl(accessControlAddress).getValidatorsSet();
        (uint burnAmount, uint remainingReward, uint baseRewardPerValidator, uint activeNumber) = _calculateBaseReward();

        uint remainingStake = totalStake - minimumStake * activeNumber;
        // validator base reward
        uint _reward = baseRewardPerValidator / CRAExponent;
        for(uint i = 0; i < validatorsSet.length; i++){
            if(!IAccessControl(accessControlAddress).isValidator(validatorsSet[i])) {
                continue;
            }
            uint256 rwAmount = _reward; // base reward
            // if stake more than minimum, get extra reward
            if(stakedAmounts[validatorsSet[i]] > minimumStake){
                uint _r = (stakedAmounts[validatorsSet[i]] - minimumStake) * remainingReward / remainingStake / CRAExponent;
                rwAmount = rwAmount + _r;
            }
            // transfer reward to validators
            payable(validatorsSet[i]).transfer(rwAmount);
            emit ClaimReward(validatorsSet[i], rwAmount);

        }
        // burn
        if(burnAmount > 0){
            payable(address(0x0)).transfer(burnAmount);
            emit ClaimReward(address(0x0), burnAmount);
        }
        lastClaimedTime = lastClaimedTime + claimedPeriod;
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

    function setStartRewardPeriod(uint256 time) external onlyOwner() {
        if (time == 0) {
            lastClaimedTime = block.timestamp + claimedPeriod;
        } else {
            lastClaimedTime = time;
        }
    }

    function changeClaimPeriod(uint newPeriod) external onlyOwner(){
        claimedPeriod = newPeriod;
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