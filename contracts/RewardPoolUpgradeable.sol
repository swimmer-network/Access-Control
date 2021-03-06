pragma solidity 0.8.10;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract RewardPoolUpgradeable is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address admin_
    ) payable TransparentUpgradeableProxy(_logic, admin_, "") {
        
    }
}