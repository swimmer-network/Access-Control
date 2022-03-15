pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract CRAM is Ownable, Initializable, ERC20, Pausable {
    mapping(address=>bool) public minters;
    bool public isTransferable;
    modifier onlyMinter(address addr) {
        require(minters[addr], "CRAM: Only minter");
        _;
    }

    modifier onlyIsTransferable() {
        require(isTransferable == true, "CRAM: not allow to transfer");
        _;
    }

    event SetMinter(address indexed addr, bool status);

    constructor () ERC20("", "") {
        minters[msg.sender] = true;
    }

    function name() public view override returns (string memory) {
        return "Crabada Amulet";
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view override returns (string memory) {
        return "CRAM";
    }

    function setTransferable(bool _isTransferable) onlyOwner() external {
        isTransferable = _isTransferable;
    }

    function initialize(address _owner) external initializer() {
        minters[_owner] = true;
        _transferOwnership(_owner);
    }

    function mint(address _to, uint256 _amount) onlyMinter(msg.sender) external {
        _mint(_to, _amount);
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

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public onlyIsTransferable override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
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

     function burnFrom(address account, uint256 amount) public {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}