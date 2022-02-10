pragma solidity 0.8.10;

// import "@openzeppelin/contracts/access/AccessControl.sol";
// import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
// import "./AccessControlStorage.sol";


contract Consensus {
    uint256 public blockLimit;
    uint256 public gasPrice;
    // address public rewardToken;
    constructor (uint _blockLimit, uint _gasPrice, address _rewardToken) {
        blockLimit = _blockLimit;
        gasPrice = _gasPrice;
        // rewardToken = _rewardToken;
    }

    function changeBlockLimit(uint newBlockLimit) external{
        require(newBlockLimit > 0, "Invalid Block Limit");
        blockLimit = newBlockLimit;
    }

    function changeGasPrice(uint newGasPrice) external{
        gasPrice = gasPrice;
    }

}
