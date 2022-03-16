pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CRA is ERC20 {
    uint256 private constant MAX_SUPPLY = 1000_000_000 * 10 ** 18; // 1B

    constructor () ERC20("CRA", "CRA") {
        _mint(msg.sender, MAX_SUPPLY);
    }
}
