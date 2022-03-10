pragma solidity 0.8.10;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./StakingStorage.sol";
import "./libs/Ownable2.sol";

contract Staking is Ownable2, Pausable, Initializable , StakingStorage {

    event Deposit(address indexed staker, uint amount);
    event AddMoreStake(address indexed staker, uint amount);
    // event StartUnstaking(address indexed staker, uint amount);
    event Unstake(address indexed staker, uint amount);
    event SetWhitelist(address indexed staker, bool isEnable);

    function initialize(address cra, uint min, uint max, uint _startTime, uint _slippage) external initializer() {
        _setOwner(msg.sender);
        CRAToken = cra;
        unstakedEpoch = 30; // wait to 30 days to withdraw stake
        minStakedAmount = min;
        maxStakedAmount = max;
        startTime = _startTime;
        slippage = _slippage;
    }

    function deposit(uint amount) external whenNotPaused() {
        require(whitelist[msg.sender] == true, "STAKING: not in whitelist");
        require(amount > minStakedAmount, "STAKING: less than minimum amount");
        Validator storage user = validatorInfo[msg.sender];

        IERC20(CRAToken).transferFrom(msg.sender, address(this), amount);
        user.stakedAmount = amount;
        emit Deposit(msg.sender, amount);
    }

    function addMoreStake(uint amount) external whenNotPaused() {
        require(whitelist[msg.sender] == true, "STAKING: not in whitelist");
        Validator storage user = validatorInfo[msg.sender];
        uint current = user.stakedAmount;
        require(current + amount <= maxStakedAmount, "STAKING: exceed max amount");
        IERC20(CRAToken).transferFrom(msg.sender, address(this), amount);
        user.stakedAmount = current + amount;

        emit AddMoreStake(msg.sender, amount);
    }

    function calculate() internal view returns(uint){
        uint r = (block.timestamp - startTime)/day;
        return r % unstakedEpoch;
    }

    function unstake() external whenNotPaused() {
        require(whitelist[msg.sender] == true, "STAKING: not in whitelist");
        Validator storage user = validatorInfo[msg.sender];
        uint r = calculate();
        require(r < slippage, "STAKING: can not unstake due to overtime");
        uint amount = user.stakedAmount;
        user.stakedAmount = 0; //update staked amount
        
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

    function changeStartsTime(uint256 value) external onlyOwner() {
        startTime = value;
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
