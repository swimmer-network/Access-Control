pragma solidity 0.8.10;


contract NativeMinter{

    mapping(address=> uint256) allowList;
    receive() payable external {

    }

    constructor() {
        allowList[msg.sender] = 2;
    }

    function mintNativeCoin(address to, uint256 amount) external {
        (bool success,) = to.call{value: amount}("");
        require(success, "can not mint");
    }


    function setAdmin(address addr) external {
        allowList[addr] = 2;
    }

    // Set [addr] to be enabled on the allow list
    function setEnabled(address addr) external {
        allowList[addr] = 1;
    }

    // Set [addr] to have no role over the allow list
    function setNone(address addr) external {
        allowList[addr] = 0;
    }

    // Read the status of [addr]
    function readAllowList(address addr) external view returns (uint256) {
        return allowList[addr];
    }
}