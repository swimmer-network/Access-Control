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

    beforeEach(async () => {
        erc20 = await CRA.new();
        Staking = await StakingContract.new();
        var stakingProxy = await StakingUpgradable.new(Staking.address, admin, []);
        Staking = await StakingContract.at(stakingProxy.address);
        await Staking.initialize(erc20.address, minStaked, maxStaked, slippage, owner);

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
        // Check event
        helper.expectEvent(tx.receipt, 'Deposit', {staker: alice, amount: new BN(deposit,10)});
        await helper.expectEvent.inTransaction(tx.receipt.transactionHash, erc20.contract, 'Transfer', {from: alice, to: Staking.address, value: new BN(deposit, 10)});

    })
    it("Deposit failed due to not in whitelist", async () => { 
        let deposit = 10
        await helper.expectRevert(Staking.deposit(deposit, {from: bob}), "STAKING: Only whitelist");

    })
    it("Deposit failed due to less than minimum stake", async () => { 
        let deposit = 10
        await Staking.setWhitelist([bob], [true]);
        await helper.expectRevert(Staking.deposit(deposit, {from: bob}), "STAKING: less than minimum amount");
    })
    it("Deposit failed due to double deposit", async () => { 
        let deposit = minStaked;
        var tx = await Staking.deposit(deposit, {from: alice});

        await helper.expectRevert(Staking.deposit(deposit, {from: alice}), "STAKING: already deposited");
    })
    it("AddMoreStake successfully", async () => { 
        let deposit = 5000
        let moreStaked = 1000
        var tx = await Staking.deposit(deposit, {from: alice});

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
        var tx = await Staking.deposit(deposit, {from: alice});

        await helper.expectRevert(Staking.addMoreStake(moreStaked, {from: alice}), "STAKING: exceed max amount");
    })

    it("AddMoreStake fail due to not deposit", async () => { 
        let deposit = 6000
        let moreStaked = 5000

        await helper.expectRevert(Staking.addMoreStake(moreStaked, {from: alice}), "STAKING: has not deposited");
    })

    it("unstake failed due to before 28 days", async () => { 
        let deposit = 6000
        var tx = await Staking.deposit(deposit, {from: alice});
        // increase time to 1 day before
        await time.increase(28*24*3600-1);
        await helper.expectRevert(Staking.unstake({from: alice}), "STAKING: not allow to unstake");
    })
    
    it("unstake failed due to over 30 days: 1s", async () => { 
        let deposit = 6000
        var tx = await Staking.deposit(deposit, {from: alice});
        // increase time to 1 second before
        await time.increase(30*24*3600+1);
        var val = await Staking.validatorInfo.call(alice);
        var now = await time.latest();
        var r = now.sub(val.depositTime).div(new BN('86400'));
        var remain = r.mod(new BN('28'))
        var q = r.div(new BN('28'))
        console.log(now.toString(), val.depositTime.toString(), r.toString(), q.toString(), remain.toString());

        await helper.expectRevert(Staking.unstake({from: alice}), "STAKING: can not unstake due to overtime");
    })

    it("unstake failed due to over 1 period but lower than 28 days: 57days 23h59s", async () => { 
        let deposit = 6000
        var tx = await Staking.deposit(deposit, {from: alice});
        // increase time to 1 second before
        await time.increase(56*24*3600-1);

        await helper.expectRevert(Staking.unstake({from: alice}), "STAKING: can not unstake due to overtime");
    })


    it("unstake successfully after 28 days + 1s", async () => { 
        let deposit = 6000
        await Staking.deposit(deposit, {from: alice});
        // increase time to 31 day before
        await time.increase(28*24*3600+1);
        let tx = await Staking.unstake({from: alice});
        await helper.expectEvent.inTransaction(tx.receipt.transactionHash, erc20.contract, 'Transfer', {to: alice, from: Staking.address, value: new BN(deposit, 10)});
    })
    it("unstake successfully after 29 days + 23h59s", async () => { 
        let deposit = 6000
        await Staking.deposit(deposit, {from: alice});
        await time.increase(29*24*3600+24*3600-1);
        let tx = await Staking.unstake({from: alice});
        await helper.expectEvent.inTransaction(tx.receipt.transactionHash, erc20.contract, 'Transfer', {to: alice, from: Staking.address, value: new BN(deposit, 10)});
    })

    it("unstake successfully after 2 periods", async () => { 
        let deposit = 6000
        await Staking.deposit(deposit, {from: alice});
        // increase time to 56 day + 1s
        await time.increase(56*24*3600+1);
        let tx = await Staking.unstake({from: alice});
        await helper.expectEvent.inTransaction(tx.receipt.transactionHash, erc20.contract, 'Transfer', {to: alice, from: Staking.address, value: new BN(deposit, 10)});
    })
    it("unstake successfully after 2 periods + 23h59s", async () => { 
        let deposit = 6000
        await Staking.deposit(deposit, {from: alice});
        // increase time to 56 day + 1day + 23h59m59s
        await time.increase(56*24*3600+2*24*3600-1);
        var val = await Staking.validatorInfo.call(alice);
        var now = await time.latest();
        var r = now.sub(val.depositTime).div(new BN('86400'));
        var remain = r.mod(new BN('28'))
        var q = r.div(new BN('28'))
        console.log(now.toString(), val.depositTime.toString(), r.toString(), q.toString(), remain.toString());

        let tx = await Staking.unstake({from: alice});
        await helper.expectEvent.inTransaction(tx.receipt.transactionHash, erc20.contract, 'Transfer', {to: alice, from: Staking.address, value: new BN(deposit, 10)});
    })


})