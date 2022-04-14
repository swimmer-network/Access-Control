pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
// import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./interface/INativeMinter.sol";

contract WTUS is Ownable, ERC20, Pausable {
    mapping(address=>bool) public minters;
    address constant MINTER_ADDRESS = 0x0200000000000000000000000000000000000001;
    // Designated Blackhole Address
    address constant BLACKHOLE_ADDRESS = 0x0000000000000000000000000000000000000000;
    string private constant TOKEN_NAME = "Wrapped Treasure Under Sea";
    string private constant TOKEN_SYMBOL = "WTUS";

    INativeMinter nativeMinter = INativeMinter(MINTER_ADDRESS);
    modifier onlyMinter(address addr) {
        require(minters[addr], "TUS: Only minter");
        _;
    }

    event SetMinter(address indexed addr, bool status);
    event Deposit(address indexed dst, uint amount);
    event Withdrawal(address indexed src, uint amount);

    constructor (address _owner) ERC20(TOKEN_NAME, TOKEN_SYMBOL) {
        minters[msg.sender] = true;
        _transferOwnership(_owner);

    }

    // function initialize(address _owner) external initializer() {
    //     minters[_owner] = true;
    //     _transferOwnership(_owner);
    // }

    function mint(address _to, uint256 _amount) onlyMinter(msg.sender) external {
        nativeMinter.mintNativeCoin(_to, _amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function setMinter(address addr, bool status) onlyOwner() external {
        minters[addr] = status;
        emit SetMinter(addr, status);
    }

    function pause() onlyOwner() external {
        _pause();
    }

    function unpause() onlyOwner() external {
        _unpause();
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) whenNotPaused() internal override {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

     function burnFrom(address account, uint256 amount) external {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        // Burn native token by sending to BLACKHOLE_ADDRESS
        payable(BLACKHOLE_ADDRESS).transfer(msg.value);
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint amount) external {
        require(balanceOf(msg.sender) >= amount);
        _burn(msg.sender, amount);
        // payable(msg.sender).transfer(amount);
        nativeMinter.mintNativeCoin(_msgSender(), amount);
        emit Withdrawal(msg.sender, amount);
    }
}