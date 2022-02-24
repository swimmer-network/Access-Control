pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./ConsensusStorage.sol";

contract Consensus is Ownable, Initializable, ConsensusStorage{
    function initialize (uint _blockLimit, uint _gasPrice, uint _blockReward) external initializer() {
        blockLimit = _blockLimit;
        gasPrice = _gasPrice;
        blockReward = _blockReward;
        isPermissioned = true;
    }

    function changeBlockLimit(uint newBlockLimit) external onlyOwner(){
        require(newBlockLimit > 0, "Invalid Block Limit");
        blockLimit = newBlockLimit;
    }

    function changeGasPrice(uint newGasPrice) external onlyOwner(){
        gasPrice = gasPrice;
    }

    function revokePermissioned() external onlyOwner(){
        require(isPermissioned == true, "Consensus: can not update permission");
        isPermissioned = false;
    }
}
