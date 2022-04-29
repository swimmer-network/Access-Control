pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "../interface/ISysAdmin.sol";

contract SysAdmin is Ownable,Initializable, ISysAdmin {
    mapping(address=>bool) nativeCoinMinters;
    mapping(address=>bool) admins;

    INativeMinter nativeMinterContract;
    IAllowList deployerContract;

    event SetMinter(address addr, bool isEnabled);
    event SetAdmin(address addr, bool isEnabled);
    event SetContractDeployer(address addr, bool isEnabled);
    event Mint(address minter, address to, uint256 amount);

    modifier onlyAdmin() {
        require(admins[msg.sender], "SA: not admin");
        _;
    }

    function initialize(INativeMinter _nativeMinter, IAllowList _deployerContract) external initializer() {
        nativeMinterContract = _nativeMinter;
        deployerContract = _deployerContract;
        _transferOwnership(msg.sender);
    }

    function mint(address to, uint256 amount) override external {
        _mint(to, amount);
    }

    function mintNativeCoin(address to, uint256 amount) override external {
        _mint(to, amount);
    }

    function _mint(address to, uint256 amount) internal {
        require(nativeCoinMinters[msg.sender], "SA: not minter");
        nativeMinterContract.mintNativeCoin(to, amount);
        emit Mint(msg.sender, to, amount);
    }


    //======================================
    // Admin
    //======================================
    function setMinter(address minter, bool isEnabled) override external onlyAdmin() {
        nativeCoinMinters[minter] = isEnabled;
        emit SetMinter(minter, isEnabled);
    }

    function setContractDeployer(address deployer, bool isEnabled) override external onlyAdmin() {
        if (isEnabled) {
            deployerContract.setEnabled(deployer);
        } else {
            deployerContract.setNone(deployer);
        }

        emit SetContractDeployer(deployer, isEnabled);
    }

    //======================================
    // Owner
    //======================================
    function setAdmin(address admin, bool isEnabled) override external onlyOwner() {
        admins[admin] = isEnabled;
        emit SetAdmin(admin, isEnabled);
    }

    function changeNativeMinterAddress(INativeMinter _nativeMinter) override external onlyOwner() {
        nativeMinterContract = _nativeMinter;
    }

    function changeContractDeployerAddress(IAllowList _deployerContract) override external onlyOwner() {
        deployerContract = _deployerContract;
    }


    //======================================
    // Read only functions
    //======================================
    function checkContractDeployer(address deployer) override external view returns (bool) {
        uint256 rs = deployerContract.readAllowList(deployer);
        return (rs==1|| rs ==2);
    }

    function checkMinter(address minter) override external view returns (bool) {
        return nativeCoinMinters[minter];
    }
    function checkAdmin(address admin) override external view returns (bool) {
        return admins[admin];
    }

    function getContractAddresses() override external view  returns (address contractDeployerAddress, address nativeMinterAddress) {
        return (address(deployerContract), address(nativeMinterContract));
    }
}