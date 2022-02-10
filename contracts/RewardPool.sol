pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IAccessControl.sol";

contract RewardPool {
    address public rewardToken;
    address public accessControlAddress;
    // uint256 public numberOfActiveValidators;
    // address[] public validatorsSet;
    mapping(address => uint256) private balanceOfWork;
    uint256 public lastClaimedTime;
    uint256 public claimedPeriod;
    constructor(address _rewardToken, address _accessControl) {
        rewardToken = _rewardToken;
        accessControlAddress = _accessControl;
    }

    function claimReward() external{
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
    }

    function balanceOf(address validator) external view returns(uint256){
        return balanceOfWork[validator];
    }
}
