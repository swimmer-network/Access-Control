pragma solidity 0.8.10;

import "../RewardPool.sol";

contract TestRewardPool is RewardPool{
    function changeLastClaimedTime() external{
        lastClaimedTime = 0;
    }
}
