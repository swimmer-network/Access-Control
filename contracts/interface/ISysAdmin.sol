
// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IAllowList.sol";
import "./INativeMinter.sol";

interface ISysAdmin {

    function mint(address to, uint256 amount) external;
    function mintNativeCoin(address to, uint256 amount) external;

    function setMinter(address minter, bool isEnabled) external;
    function setContractDeployer(address deployer, bool isEnabled) external;

    function setAdmin(address admin, bool isEnabled) external;

    function changeNativeMinterAddress(INativeMinter _nativeMinter) external;
    function changeContractDeployerAddress(IAllowList _deloyerContract) external;

    function checkContractDeployer(address deployer) external view returns (bool);
    function checkMinter(address minter) external view returns (bool);
    function checkAdmin(address admin) external view returns (bool);
    function getContractAddresses() external view returns (address contractDeployerAddress, address nativeMinterAddress);
}