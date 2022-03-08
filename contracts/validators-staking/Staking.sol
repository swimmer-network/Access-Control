pragma solidity 0.8.10;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./StakingStorage.sol";
import "./libs/Ownable2.sol";

contract Staking is Ownable2, Pausable, Initializable , StakingStorage {

    event Deposit(address indexed staker, uint amount);
    event AddMoreStake(address indexed staker, uint amount);
    event StartUnstaking(address indexed staker, uint amount);
    event Unstake(address indexed staker, uint amount);
    event SetWhitelist(address indexed staker, bool isEnable);

    function initialize(address cra, uint min, uint max) external initializer() {
        _setOwner(msg.sender);
        CRAToken = cra;
        unstakedEpoch = 21 days; // wait to 21 days to withdraw stake
        minStakedAmount = min;
        maxStakedAmount = max;
    }

    function deposit(uint amount) external whenNotPaused() {
        require(amount > minStakedAmount, "STAKING: less than minimum amount");

        Validator storage user = validatorInfo[msg.sender];

        IERC20(CRAToken).transferFrom(msg.sender, address(this), amount);
        user.stakedAmount = amount;
        emit Deposit(msg.sender, amount);
    }

    function addMoreStake(uint amount) external whenNotPaused() {
        Validator storage user = validatorInfo[msg.sender];
        uint current = user.stakedAmount;
        require(current + amount <= maxStakedAmount, "STAKING: exceed max amount");
        IERC20(CRAToken).transferFrom(msg.sender, address(this), amount);
        user.stakedAmount = current + amount;

        emit AddMoreStake(msg.sender, amount);
    }

    function startUnstaking(uint amount) external whenNotPaused() {
        Validator storage user = validatorInfo[msg.sender];
        user.lastStartUnstaking = block.timestamp; // update start unstaking time
        require(user.stakedAmount - user.unstakingAmount >= amount, "STAKING: staked amount is less than withdraw amount");
        
        user.unstakingAmount += amount; // update unstaking amount
        require(user.stakedAmount >= user.unstakingAmount, "STAKING: staked amount is less than unstaking amount");
        
        emit StartUnstaking(msg.sender, amount);
    }

    function unstake(uint amount) external whenNotPaused() {
        Validator storage user = validatorInfo[msg.sender];
        require(user.unstakingAmount >= amount, "STAKING: staking amount is less than withdraw amount");
        require(user.lastStartUnstaking + unstakedEpoch <= block.timestamp, "STAKING: Not allow to unstake due to 21 days restriction");
        
        user.unstakingAmount -= amount; // update unstaking amount
        user.stakedAmount -= amount; //update staked amount
        
        require(user.stakedAmount >= user.unstakingAmount, "STAKING: staked amount is less than unstaking amount");

        IERC20(CRAToken).transfer(msg.sender, amount);

        emit Unstake(msg.sender, amount);
    }

    // function setWhitelist(address[] calldata stakers, bool[] calldata tf) external onlyOwner() {
    //     require(stakers.length == tf.length, "STAKING: invalid params length");
    //     for(uint i; i < stakers.length; i++){
    //         whitelist[stakers[i]] = tf[i];
    //         emit SetWhitelist(stakers[i], tf[i]);
    //     }
    // }

    function changeUnstakeEpoch(uint value) external onlyOwner(){
        unstakedEpoch = value;
    }

    // function setStartsTime(uint256 start) external onlyOwner() {
    //     startTime = start;
    // }

    function setPause(bool isPaused) external onlyOwner() {
        if (isPaused) {
            _pause();
        } else {
            _unpause();
        }
    }
}
