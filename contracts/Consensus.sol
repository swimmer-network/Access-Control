pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ConsensusStorage.sol";

contract Consensus is Ownable, ConsensusStorage{
    // address public rewardToken;
    constructor (uint _blockLimit, uint _gasPrice, address _rewardToken) {
        blockLimit = _blockLimit;
        gasPrice = _gasPrice;
        // rewardToken = _rewardToken;
    }

    function changeBlockLimit(uint newBlockLimit) external onlyOwner(){
        require(newBlockLimit > 0, "Invalid Block Limit");
        blockLimit = newBlockLimit;
    }

    function changeGasPrice(uint newGasPrice) external onlyOwner(){
        gasPrice = gasPrice;
    }

}
