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
        address ecosystemAddr,
        uint burnPercent, // 25%
        uint ecosystemPoolPercent, // 10%
        uint minimum,
        uint maximum,
        uint baseRate
    ) external initializer() {
        accessControlAddress = _accessControl;
        burnRate = burnPercent;
        ecosystemRate = ecosystemPoolPercent;
        minimumStake = minimum;
        maximumStake = maximum;
        baseRewardRate = baseRate;
        claimedPeriod = 2 weeks;
        ecosystemAddress = ecosystemAddr;
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
        (uint ecosystemAmount, uint burnAmount, uint remainingReward, uint baseRewardPerValidator, uint activeNumber) = _calculateBaseReward();

        uint remainingStake = totalStake - minimumStake * activeNumber;
        // validator base reward
        uint _reward = baseRewardPerValidator;
        for(uint i = 0; i < validatorsSet.length; i++){
            if(!IAccessControl(accessControlAddress).isValidator(validatorsSet[i])) {
                continue;
            }
            uint256 rwAmount = _reward; // base reward
            // if stake more than minimum, get extra reward
            if(stakedAmounts[validatorsSet[i]] > minimumStake){
                rwAmount = rwAmount + ((stakedAmounts[validatorsSet[i]] - minimumStake) * remainingReward / remainingStake);
                // rwAmount = rwAmount + _r;
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
        if (ecosystemAmount > 0) {
            payable(ecosystemAddress).transfer(ecosystemAmount);
            emit ClaimReward(ecosystemAddress, ecosystemAmount);
        }
        lastClaimedTime = lastClaimedTime + claimedPeriod;
    }

    function balanceOfStake(address validator) external view returns(uint256){
        return stakedAmounts[validator];
    }

    function _calculateBaseReward() public view returns(uint,uint,uint,uint,uint){
        uint currentRewardBalance = address(this).balance;
        uint burnAmount = currentRewardBalance * burnRate / rateDecimals;
        uint ecosystemAmount = currentRewardBalance * ecosystemRate / rateDecimals;
        uint activeNumber = IAccessControl(accessControlAddress).numberOfActiveValidators();

        uint rewardAfterBurn = currentRewardBalance - burnAmount - ecosystemAmount;
        uint totalBaseReward = rewardAfterBurn * baseRewardRate / rateDecimals;
        uint remainingReward = rewardAfterBurn - totalBaseReward;
        uint baseRewardPerValidator = totalBaseReward / activeNumber;

        return (ecosystemAmount, burnAmount, remainingReward, baseRewardPerValidator, activeNumber);
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

    function changeRate(uint burnPercent, uint ecosystemPoolPercent) external onlyOwner() {
        burnRate = burnPercent;
        ecosystemRate = ecosystemPoolPercent;
    }

    function changeEcosystemAddress(address addr) external onlyOwner() {
        ecosystemAddress = addr;
    }

    fallback() external payable {
        
    }
}