pragma solidity 0.8.10;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./StakingStorage.sol";

contract Staking is Ownable, Pausable, Initializable , StakingStorage {

    event Deposit(address indexed staker, uint indexed amount, uint depositTime);
    event AddMoreStake(address indexed staker, uint amount);
    event Unstake(address indexed staker, uint amount);
    event SetWhitelist(address indexed staker, bool isEnable);

    modifier onlyWhitelist() {
        require(whitelist[msg.sender] ==  true, "STAKING: Only whitelist");
        _;
    }

    function initialize(address cra, uint min, uint max, uint _slippage, address _owner) external initializer() {
        CRAToken = cra;
        unstakedEpoch = 28; // wait to 28 days to withdraw stake
        minStakedAmount = min;
        maxStakedAmount = max;
        slippage = _slippage;
        _transferOwnership(_owner);

    }

    function deposit(uint amount) external whenNotPaused() onlyWhitelist(){
        require(amount >= minStakedAmount, "STAKING: less than minimum amount");
        require(amount <= maxStakedAmount, "STAKING: greater than maximum amount");

        Validator storage user = validatorInfo[msg.sender];

        require(user.stakedAmount == 0 && user.depositTime == 0, "STAKING: already deposited");
        IERC20(CRAToken).transferFrom(msg.sender, address(this), amount);
        user.stakedAmount = amount;
        user.depositTime = block.timestamp;

        //update total stake
        totalStake = totalStake + amount;
        emit Deposit(msg.sender, amount, block.timestamp);
    }

    function addMoreStake(uint amount) external whenNotPaused() onlyWhitelist() {
        Validator storage user = validatorInfo[msg.sender];
        uint current = user.stakedAmount;
        require(user.depositTime > 0, "STAKING: has not deposited");
        require(current + amount <= maxStakedAmount, "STAKING: exceed max amount");
        IERC20(CRAToken).transferFrom(msg.sender, address(this), amount);
        user.stakedAmount = current + amount;
        
        //update total stake
        totalStake = totalStake + amount;

        emit AddMoreStake(msg.sender, amount);
    }

    function calculate(uint depositTime) internal view returns(uint, uint){
        uint r = (block.timestamp - depositTime)/day;
        uint remainder = r % unstakedEpoch;
        uint quotient = r / unstakedEpoch;
        return (quotient, remainder);
    }

    function unstake() external whenNotPaused() onlyWhitelist(){
        Validator storage user = validatorInfo[msg.sender];
        (uint quotient, uint remainder) = calculate(user.depositTime);
        require(quotient > 0, "STAKING: not allow to unstake");
        require(remainder < slippage, "STAKING: can not unstake due to overtime");
        uint amount = user.stakedAmount;
        user.stakedAmount = 0; //update staked amount
        user.depositTime = 0;

        totalStake = totalStake - amount;
        
        IERC20(CRAToken).transfer(msg.sender, amount);
        emit Unstake(msg.sender, amount);
    }

    function setWhitelist(address[] calldata stakers, bool[] calldata tf) external onlyOwner() {
        require(stakers.length == tf.length, "STAKING: invalid params length");
        for(uint i; i < stakers.length; i++){
            whitelist[stakers[i]] = tf[i];
            emit SetWhitelist(stakers[i], tf[i]);
        }
    }

    function changeMinimumStake(uint value) external onlyOwner(){
        minStakedAmount = value;
    }

    function changeMaximumStake(uint value) external onlyOwner(){
        maxStakedAmount = value;
    }

    function changeUnstakeEpoch(uint value) external onlyOwner(){
        unstakedEpoch = value;
    }

    function changeSlippage(uint256 value) external onlyOwner() {
        slippage = value;
    }

    function setPause(bool isPaused) external onlyOwner() {
        if (isPaused) {
            _pause();
        } else {
            _unpause();
        }
    }
}
