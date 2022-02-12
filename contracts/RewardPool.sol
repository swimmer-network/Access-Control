pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IAccessControl.sol";
import "./RewardPoolStorage.sol";


contract RewardPool is Ownable, RewardPoolStorage{
    constructor(address _rewardToken, address _accessControl) {
        rewardToken = _rewardToken;
        accessControlAddress = _accessControl;
    }

    function claimReward() external{
        require(lastClaimedTime + claimedPeriod < block.timestamp, "RewardPool: not allow to claim");
        uint currentRewardBalance = IERC20(rewardToken).balanceOf(address(this));
        uint numberOfActiveValidator = IAccessControl(accessControlAddress).getNumberOfValidators();
        address[] memory validatorsSet = IAccessControl(accessControlAddress).getValidatorsSet();
        uint rewardPerWORK = currentRewardBalance/numberOfActiveValidator;
        for(uint i = 0; i < validatorsSet.length; i++){
            if(validatorsSet[i] != address(0x0) && IAccessControl(accessControlAddress).isValidator(validatorsSet[i])){
                //reset balance of WORK to 0
                balanceOfWork[validatorsSet[i]] = 0;
                // transfer reward to validators
                IERC20(rewardToken).transfer(validatorsSet[i], rewardPerWORK);
            }
        }
        lastClaimedTime = block.timestamp;
    }

    function changeClaimPeriod(uint newPeriod) external onlyOwner(){
        claimedPeriod = newPeriod;
    }

    function balanceOf(address validator) external view returns(uint256){
        return balanceOfWork[validator];
    }
}
