const CRA = artifacts.require("CRA");
const StakingContract = artifacts.require("Staking");
const StakingUpgradable = artifacts.require("StakingUpgradeable");
const helper = require('@openzeppelin/test-helpers');
const expectEvent = require('@openzeppelin/test-helpers/src/expectEvent');
const expectRevert = require('@openzeppelin/test-helpers/src/expectRevert');
const {time } = require('@openzeppelin/test-helpers');
const { assert } = require('chai');

// const Common = require('./common.js');
// const advanceT = helper.time;

const BN = helper.BN;

contract("Staking", async ([owner, admin, alice, bob]) => {
    var erc20, Staking;
    var mintAmount = "1000000"
    var minStaked = "100"
    var maxStaked = "10000"
    var slippage = 2 //days
    var emptyData = Buffer.from("", "hex");

    before(async () => {
        erc20 = await CRA.new();
        Staking = await StakingContract.new();
        // await Staking.initialize('CRA Amulet', 'AML', erc20.address);
        await Staking.initialize(erc20.address, minStaked, maxStaked, slippage);
        // await Staking.changeClaimEpoch(0);
        // await Staking.changeUnstakeEpoch(0);

        await erc20.transfer(alice, mintAmount);
        await erc20.transfer(bob, mintAmount);

        await erc20.approve(Staking.address, mintAmount, { from: alice })
        await erc20.approve(Staking.address, mintAmount, { from: bob })

        await Staking.setWhitelist([alice], [true]);

    })

    it("Deposit", async () => { 
        let deposit = 5000
        var tx = await Staking.deposit(deposit, {from: alice});
        let aliceInfo = await Staking.validatorInfo(alice);
        let aliceStakedAmount = new BN(aliceInfo.stakedAmount, 10).toNumber()
        assert.equal(deposit, aliceStakedAmount);
        // // Check event
        // helper.expectEvent(tx.receipt, 'Deposit', {staker: alice, amount: new BN(deposit,10)});
        await helper.expectEvent.inTransaction(tx.receipt.transactionHash, erc20.contract, 'Transfer', {from: alice, to: Staking.address, value: new BN(deposit, 10)});

    })
    it("Deposit failed due to not in whitelist", async () => { 
        let deposit = 10
        // // Check event
        await helper.expectRevert(Staking.deposit(deposit, {from: bob}), "STAKING: Only whitelist");

    })
    it("Deposit failed due to less than minimum stake", async () => { 
        let deposit = 10
        await Staking.setWhitelist([bob], [true]);
        
        // Check event
        await helper.expectRevert(Staking.deposit(deposit, {from: bob}), "STAKING: less than minimum amount");

    })
    it("AddMoreStake successfully", async () => { 
        let deposit = 5000
        let moreStaked = 1000
        
        var tx = await Staking.addMoreStake(moreStaked, {from: alice});
        let aliceInfo = await Staking.validatorInfo(alice);
        let aliceStakedAmount = new BN(aliceInfo.stakedAmount, 10).toNumber()
        assert.equal(deposit+moreStaked, aliceStakedAmount);
        // // Check event
        // helper.expectEvent(tx.receipt, 'Deposit', {staker: alice, amount: new BN(deposit,10)});
        await helper.expectEvent.inTransaction(tx.receipt.transactionHash, erc20.contract, 'Transfer', {from: alice, to: Staking.address, value: new BN(moreStaked, 10)});

    })
    it("AddMoreStake fail due to excess max stake", async () => { 
        let deposit = 6000
        let moreStaked = 5000
        
        await helper.expectRevert(Staking.addMoreStake(deposit, {from: alice}), "STAKING: exceed max amount");

    })

    // it("claim", async () => { 
    //     let deposit = 10000

    //     let tx = await Staking.claim({from: alice});
    //     let AMLBal = await Staking.balanceOf(alice);
    //     assert.equal(2, AMLBal);
        
    //     // // Check event
    //     helper.expectEvent(tx.receipt, 'Claim', {staker: alice, amount: new BN(2,10)});
    //     helper.expectEvent(tx.receipt, 'Transfer', {from: '0x0000000000000000000000000000000000000000', to: alice, value: new BN(2, 10)});
    // })

    it("unstake failed due to before 1 month", async () => { 
        // increase time to 1 day before
        await time.increase(29*24*3600);
        await helper.expectRevert(Staking.unstake({from: alice}), "STAKING: can not unstake due to overtime");
    })
    it("unstake successfully after 1 month and 2 days", async () => { 
        let deposit = 6000
        // increase time to 31 day before
        await time.increase(31*24*3600);
        // await helper.expectRevert(Staking.unstake({from: alice}), "STAKING: can not unstake due to overtime");
        let tx = await Staking.unstake({from: alice});
        await helper.expectEvent.inTransaction(tx.receipt.transactionHash, erc20.contract, 'Transfer', {to: alice, from: Staking.address, value: new BN(deposit, 10)});
    })

    it("unstake failed after 1 month and 2 days 1 second", async () => { 
        // increase time to 32 day + 1 second
        await time.increase(32*24*3600 + 1);
        await helper.expectRevert(Staking.unstake({from: alice}), "STAKING: can not unstake due to overtime");
    })

})