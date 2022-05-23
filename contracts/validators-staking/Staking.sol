pragma solidity 0.8.10;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./StakingStorage.sol";
import "./libs/Ownable2.sol";

contract Staking is Ownable2, Pausable, Initializable , StakingStorage {

    event Deposit(address indexed staker, uint indexed amount, uint depositTime);
    event AddMoreStake(address indexed staker, uint amount);
    event Unstake(address indexed staker, uint amount);
    event SetWhitelist(address indexed staker, bool isEnable);

    modifier onlyWhitelist() {
        require(whitelist[msg.sender] ==  true, "STAKING: Only whitelist");
        _;
    }

    function initialize(address cra, uint min, uint max, uint _slippage, address _owner) external initializer() {
        _setOwner(msg.sender);
        CRAToken = cra;
        unstakedEpoch = 28; // wait to 28 days to withdraw stake
        minStakedAmount = min;
        maxStakedAmount = max;
        slippage = _slippage;
        transferOwnership(_owner);

    }

    function deposit(uint amount) external whenNotPaused() onlyWhitelist(){
        require(amount >= minStakedAmount, "STAKING: less than minimum amount");

        Validator storage user = validatorInfo[msg.sender];

        require(user.stakedAmount == 0 && user.depositTime == 0, "Staking: already deposited");
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
        require(user.depositTime > 0, "Staking: has not deposited");
        require(current + amount <= maxStakedAmount, "STAKING: exceed max amount");
        IERC20(CRAToken).transferFrom(msg.sender, address(this), amount);
        user.stakedAmount = current + amount;
        
        //update total stake
        totalStake = totalStake + amount;

        emit AddMoreStake(msg.sender, amount);
    }

    function calculate(uint depositTime) internal view returns(uint){
        uint r = (block.timestamp - depositTime)/day;
        return r % unstakedEpoch;
    }

    function unstake() external whenNotPaused() onlyWhitelist(){
        Validator storage user = validatorInfo[msg.sender];
        uint r = calculate(user.depositTime);
        require(r < slippage, "STAKING: can not unstake due to overtime");
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
