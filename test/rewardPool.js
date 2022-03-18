const CRA = artifacts.require("CRA");
const TUS = artifacts.require("TUS");
const RewardPoolContract = artifacts.require("TestRewardPool");
const ACContract = artifacts.require("SwimmerNetworkAC")
const helper = require('@openzeppelin/test-helpers');
const expectEvent = require('@openzeppelin/test-helpers/src/expectEvent');
const expectRevert = require('@openzeppelin/test-helpers/src/expectRevert');
const {time } = require('@openzeppelin/test-helpers');
const { assert } = require('chai');

// const Common = require('./common.js');
// const advanceT = helper.time;

const BN = helper.BN;

contract("RewardPool", async ([owner, admin, alice, bob, val5, val6,val7,val8,val9,val10]) => {
    var erc20, RewardPool;
    var mintAmount = "10000"
    var minStaked = "100"
    var maxStaked = "10000"
    var slippage = 2 //days
    var emptyData = Buffer.from("", "hex");
    var burnRate = 2000 // 2000/10000 = 20.00%
    var baseRate = 250 // 250/10000 = 2.5%

    // rewardAfterBurn = 8000* 10^12
    // totalBaseReward = rewardAfterBurn * 2.5% = 8000*2.5% = 200 * 10^12
    // remainingReward = rewardAfterBurn - totalBaseReward = (8000-200) * 10^12= 7800 * 10^12
    // baseRewardPerValidator = totalBaseReward /2 = 200 /2 * 10^12 = 100 * 10^12

    before(async () => {
        erc20 = await CRA.new();
        SwimmerAC = await ACContract.new();

        // init swimmer contract and add validator
        await SwimmerAC.initialize([admin]);
        await SwimmerAC.addValidators([alice, bob], {from: admin});
        // await SwimmerAC.addValidators([owner, admin, alice, bob, val5, val6,val7,val8,val9,val10], {from: admin});

        RewardPool = await RewardPoolContract.new();

        await RewardPool.initialize(owner, erc20.address,SwimmerAC.address, burnRate, minStaked, maxStaked, baseRate);
        // await RewardPool.changeClaimEpoch(0);
        // await RewardPool.changeUnstakeEpoch(0);

        // await erc20.transfer(alice, mintAmount);
        // await erc20.transfer(bob, mintAmount);

        // await erc20.approve(RewardPool.address, mintAmount, { from: alice })
        // await erc20.approve(RewardPool.address, mintAmount, { from: bob })

        // await RewardPool.setWhitelist([alice], [true]);

    })

    it("Add validator", async () => { 
        let deposit = 5000
        await helper.expectRevert(RewardPool.addValidatorsStake([alice, bob], [99, 99], {from:owner}), "must be greater than minimum");
        await helper.expectRevert(RewardPool.addValidatorsStake([alice, bob], [10001, 10001], {from:owner}), "must be less than maximum");

        // var tx = await RewardPool.addValidatorsStake([alice, bob], [deposit, deposit], {from: owner});
        var tx = await RewardPool.addValidatorsStake([alice, bob], [deposit, deposit], {from: owner});

        
        let aliceStaked = await RewardPool.stakedAmounts(alice);
        assert.equal(deposit, new BN(aliceStaked, 10).toNumber());
        
        let bobStaked = await RewardPool.stakedAmounts(bob);
        assert.equal(deposit, new BN(bobStaked, 10).toNumber());

        let totalStaked = await RewardPool.totalStake();
        assert.equal(new BN(aliceStaked, 10).toNumber() + new BN(bobStaked, 10).toNumber(), new BN(totalStaked, 10).toNumber())

    })
    it("Claim reward", async () => { 
        // let list = await SwimmerAC.getValidatorsSet();
        // console.log(list)
        await erc20.transfer(RewardPool.address, mintAmount);
        // let b = await erc20.balanceOf(owner);
        // console.log(new BN(b, 10).toString())
        await RewardPool.claimReward()

        let ATus = await erc20.balanceOf(alice);
        let BTus = await erc20.balanceOf(bob);
        

        assert.equal((mintAmount - 0.2*mintAmount)/2, new BN(ATus, 10).toNumber());
        assert.equal((mintAmount - 0.2*mintAmount)/2, new BN(BTus, 10).toNumber());

    })

    it("all has minimum accept the last one", async () => { 
        let deposit = 100

        await RewardPool.changeLastClaimedTime();
        await SwimmerAC.addValidators([owner, admin, val5, val6,val7,val8,val9,val10], {from: admin});

        var tx = await RewardPool.reduceValidatorsStake([alice, bob], [5000,5000], {from:owner})

        var tx = await RewardPool.addValidatorsStake([owner, admin, alice, bob, val5, val6,val7,val8,val9,val10
        ], [deposit, deposit,deposit, deposit,deposit, deposit,deposit, deposit,deposit, deposit*2], {from: owner});
        await erc20.transfer(RewardPool.address, mintAmount);
        let beforeATus = await erc20.burn(await erc20.balanceOf(alice), {from: alice});

        await RewardPool.claimReward()
        let ATus = await erc20.balanceOf(alice);
        let Val10Tus = await erc20.balanceOf(val10);
        let Val6Tus = await erc20.balanceOf(val6)

        assert.equal(new BN(ATus, 10).toNumber(), (mintAmount - 0.2*mintAmount)*0.025/10);
        assert.equal(new BN(Val6Tus, 10).toNumber(), (mintAmount - 0.2*mintAmount)*0.025/10);

        assert.equal(new BN(Val10Tus, 10).toNumber(), 7820);
    })

    it("all has minimum accept validator 9 and 10", async () => { 
        let deposit = 100

        await RewardPool.changeLastClaimedTime();
        // await SwimmerAC.addValidators([owner, admin, val5, val6,val7,val8,val9,val10], {from: admin});

        // var tx = await RewardPool.reduceValidatorsStake([alice, bob], [5000,5000], {from:owner})
        
        var tx = await RewardPool.reduceValidatorsStake([owner, admin, alice, bob, val5, val6,val7,val8,val9,val10
        ], [deposit, deposit,deposit, deposit,deposit, deposit,deposit, deposit,deposit, deposit*2], {from: owner});
        
        await RewardPool.updateValidatorsStake([owner, admin, alice, bob, val5, val6,val7,val8,val9,val10
        ], [deposit, deposit,deposit, deposit,deposit, deposit,deposit, deposit,deposit*2, deposit*3], {from: owner});
       
        await erc20.transfer(RewardPool.address, mintAmount);
        let beforeATus = await erc20.burn(await erc20.balanceOf(alice), {from: alice});
        let beforeVal10Tus = await erc20.burn(await erc20.balanceOf(val10), {from: val10});
        let beforeVal9Tus = await erc20.burn(await erc20.balanceOf(val9), {from: val9});


        await RewardPool.claimReward()
        let ATus = await erc20.balanceOf(alice);
        let Val10Tus = await erc20.balanceOf(val10);
        let Val9Tus = await erc20.balanceOf(val9)

        assert.equal(new BN(ATus, 10).toNumber(), 20);
        assert.equal(new BN(Val9Tus, 10).toNumber(), 2620);

        assert.equal(new BN(Val10Tus, 10).toNumber(), 5220);
    })

    it("all validators have same stake", async () => { 
        let deposit = 100

        await RewardPool.changeLastClaimedTime();

        var tx = await RewardPool.updateValidatorsStake([owner, admin, alice, bob, val5, val6,val7,val8,val9
        ], [deposit*2, deposit*2,deposit*2, deposit*2,deposit*2, deposit*2,deposit*2, deposit*2,deposit], {from: owner});
        await erc20.transfer(RewardPool.address, mintAmount);
        let beforeATus = await erc20.burn(await erc20.balanceOf(alice), {from: alice});
        let tx1 = await erc20.burn(await erc20.balanceOf(val10), {from: val10});
        let beforeVal9Tus = await erc20.burn(await erc20.balanceOf(val9), {from: val9});

        await RewardPool.claimReward()
        let ATus = await erc20.balanceOf(alice);
        let Val10Tus = await erc20.balanceOf(val10);
        let Val9Tus = await erc20.balanceOf(val9)

        assert.equal(new BN(ATus, 10).toNumber(), 800);
        assert.equal(new BN(Val9Tus, 10).toNumber(), 800);

        assert.equal(new BN(Val10Tus, 10).toNumber(), 800);
    })

})