
const RewardPoolContract = artifacts.require("RewardPool");
const RewardPoolUpgradeable = artifacts.require("RewardPoolUpgradeable");
const ACContract = artifacts.require("SwimmerNetworkAC")
const helper = require('@openzeppelin/test-helpers');
const expectEvent = require('@openzeppelin/test-helpers/src/expectEvent');
const expectRevert = require('@openzeppelin/test-helpers/src/expectRevert');
const {time, balance } = require('@openzeppelin/test-helpers');
const { assert } = require('chai');
const { web3 } = require('@openzeppelin/test-helpers/src/setup');
const { ZERO_ADDRESS } = require('@openzeppelin/test-helpers/src/constants');

// const Common = require('./common.js');
// const advanceT = helper.time;

const BN = helper.BN;

contract("RewardPool", async ([owner, admin, alice, bob, ecosystemAddr, val1, val2,val3,val4,val5, val6,val7,val8,val9,val10,val11,val12,val13,val14,val15,val16,val17,val18,val19,val20]) => {
    var erc20, RewardPool;
    var mintAmount = "10000"
    var minStaked = new BN("50000000000000000000000"); // 50k
    var maxStaked = new BN("1000000000000000000000000"); // 1M
    var burnRate = new BN(2000) // 2000/10000 = 20.00%
    var ecosystemRate = new BN(1000) // 1000/10000 = 10.00%
    var baseRate = new BN(250) // 250/10000 = 2.5%
    var BN1 = new BN(1)
    var PERCENT_BASE = new BN('10000')

    var claimPeriod = time.duration.weeks(2);
    var dec = new BN(10).pow(new BN(18))

    beforeEach(async () => {
        // init swimmer contract and add validator
        SwimmerAC = await ACContract.new();
        await SwimmerAC.initialize([admin]);

        RewardPool = await RewardPoolContract.new();
        var rwPoolProxy = await RewardPoolUpgradeable.new(RewardPool.address, admin);
        RewardPool = await RewardPoolContract.at(rwPoolProxy.address);
        await RewardPool.initialize(
            owner,
            SwimmerAC.address,
            ecosystemAddr,
            burnRate,
            '0',
            minStaked,
            maxStaked,
            baseRate
        );

    })

    it("Add validator", async () => { 
        let deposit = minStaked;
        await SwimmerAC.addValidators([alice, bob], {from: admin});

        await helper.expectRevert(RewardPool.addValidatorsStake([alice, bob], [minStaked, minStaked], {from:bob}), "Ownable: caller is not the owne");
        await helper.expectRevert(RewardPool.addValidatorsStake([val1, alice], [minStaked, minStaked], {from:owner}), "Not validator");
        await helper.expectRevert(RewardPool.addValidatorsStake([alice, bob], [minStaked.sub(BN1), minStaked.sub(BN1)], {from:owner}), "must be greater than minimum");
        await helper.expectRevert(RewardPool.addValidatorsStake([alice, bob], [maxStaked.add(BN1), maxStaked.add(BN1)], {from:owner}), "must be less than maximum");

        var tx = await RewardPool.addValidatorsStake([alice, bob], [deposit, deposit], {from: owner});
        let aliceStaked = await RewardPool.stakedAmounts(alice);
        assert.equal(deposit.toString(), aliceStaked.toString());
        
        let bobStaked = await RewardPool.stakedAmounts(bob);
        assert.equal(deposit.toString(), bobStaked.toString());

        let totalStaked = await RewardPool.totalStake();
        assert.equal(totalStaked.toString(), deposit.add(deposit).toString())
    })

    it("Increase stake for validators", async () => { 
        let deposit = minStaked;
        await SwimmerAC.addValidators([alice, bob], {from: admin});
        var tx = await RewardPool.addValidatorsStake([alice, bob], [deposit, deposit], {from: owner});
        
        await helper.expectRevert(RewardPool.updateValidatorsStake([alice, bob], [minStaked, minStaked], {from:bob}), "Ownable: caller is not the owne");
        await helper.expectRevert(RewardPool.updateValidatorsStake([val1, alice], [minStaked, minStaked], {from:owner}), "Not validator");
        await helper.expectRevert(RewardPool.updateValidatorsStake([alice, bob], [minStaked, maxStaked], {from:owner}), "must be less than maximum");
        
        var tx = await RewardPool.updateValidatorsStake([alice, bob], [minStaked, minStaked], {from: owner});

        let aliceStaked = await RewardPool.stakedAmounts.call(alice);
        assert.equal(deposit.add(minStaked).toString(), aliceStaked.toString());
        
        let bobStaked = await RewardPool.stakedAmounts.call(bob);
        assert.equal(deposit.add(minStaked).toString(), bobStaked.toString());

        let totalStaked = await RewardPool.totalStake();
        assert.equal(totalStaked.toString(), aliceStaked.add(bobStaked).toString())
    })
    it("Descrease stake for validators", async () => { 
        let deposit = minStaked;
        await SwimmerAC.addValidators([alice, bob], {from: admin});
        var tx = await RewardPool.addValidatorsStake([alice, bob], [deposit, deposit], {from: owner});
        
        await helper.expectRevert(RewardPool.reduceValidatorsStake([alice, bob], [minStaked, minStaked], {from:bob}), "Ownable: caller is not the owne");
        await helper.expectRevert(RewardPool.reduceValidatorsStake([val1, alice], [minStaked, minStaked], {from:owner}), "Not validator");
        await helper.expectRevert(RewardPool.reduceValidatorsStake([alice, bob], [minStaked, maxStaked], {from:owner}), "inefficient staked amount");
        
        var tx = await RewardPool.reduceValidatorsStake([alice, bob], [minStaked.div(new BN(2)), minStaked], {from: owner});

        let aliceStaked = await RewardPool.stakedAmounts.call(alice);
        assert.equal(deposit.div(new BN(2)).toString(), aliceStaked.toString());
        
        let bobStaked = await RewardPool.stakedAmounts.call(bob);
        assert.equal(deposit.sub(minStaked).toString(), bobStaked.toString());

        let totalStaked = await RewardPool.totalStake();
        assert.equal(totalStaked.toString(), aliceStaked.add(bobStaked).toString())
    })

    it("Claim reward: 2 min", async () => {
        await SwimmerAC.addValidators([alice, bob], {from: admin});

        await web3.eth.sendTransaction({from: owner, to: RewardPool.address, value: '100'})
        var rewardInfo = calculateReward(new BN('100'), burnRate, new BN(0), new BN(2));
        var tx = await RewardPool.addValidatorsStake([alice, bob], [minStaked, minStaked], {from: owner});

        await RewardPool.setStartRewardPeriod(0);
        await time.increase(time.duration.weeks(3));
        var tx = await RewardPool.claimReward();
        expectEvent(tx, 'ClaimReward', {to: alice, amount: rewardInfo.baseReward.toString()});
        expectEvent(tx, 'ClaimReward', {to: bob, amount: rewardInfo.baseReward.toString()});
        expectEvent(tx, 'ClaimReward', {to: ZERO_ADDRESS, amount: rewardInfo.burnAmount.toString()});
    })

    it("Claim reward: 2 min, 1 middle, 1 max", async () => {
        await SwimmerAC.addValidators([val1, val2, val3, val4, val5], {from: admin});
        await SwimmerAC.removeValidators([4], {from: admin});

        var totalFund = new BN('10000000000000000000'); // 10eth
        await web3.eth.sendTransaction({from: owner, to: RewardPool.address, value: totalFund})
        var rewardInfo = calculateReward(totalFund, burnRate, new BN(0), new BN(4));
        var extraTotalReward = rewardInfo.totalReward.sub(rewardInfo.totalBaseReward);
        
        var val3Stake =  maxStaked.div(new BN(2));
        var val4Stake = maxStaked;
        var totalOverStake = val3Stake.sub(minStaked).add(val4Stake.sub(minStaked));
        var val3Reward = extraTotalReward.mul(val3Stake.sub(minStaked)).div(totalOverStake).add(rewardInfo.baseReward);
        var val4Reward = extraTotalReward.mul(val4Stake.sub(minStaked)).div(totalOverStake).add(rewardInfo.baseReward);

        var tx = await RewardPool.addValidatorsStake([val1, val2, val3, val4], [minStaked, minStaked, val3Stake, val4Stake], {from: owner});

        var val1Tracker = await balance.tracker(val1);
        var val2Tracker = await balance.tracker(val2);
        var val3Tracker = await balance.tracker(val3);
        var val4Tracker = await balance.tracker(val4);

        await RewardPool.setStartRewardPeriod(0);
        await time.increase(time.duration.weeks(3));
        var tx = await RewardPool.claimReward();

        checkClaimEvent(tx.receipt.logs[0], val1, rewardInfo.baseReward);
        checkClaimEvent(tx.receipt.logs[1], val2, rewardInfo.baseReward);
        checkClaimEvent(tx.receipt.logs[2], val3, val3Reward);
        checkClaimEvent(tx.receipt.logs[3], val4, val4Reward);
        checkClaimEvent(tx.receipt.logs[4], ZERO_ADDRESS, rewardInfo.burnAmount);

        assert.equal(rewardInfo.baseReward.toString(), (await val1Tracker.delta()).toString())
        assert.equal(rewardInfo.baseReward.toString(), (await val2Tracker.delta()).toString())
        assert.equal(val3Reward.toString(), (await val3Tracker.delta()).toString())
        assert.equal(val4Reward.toString(), (await val4Tracker.delta()).toString())
    })

    it("Claim reward: 18 min, 1 middle, 1 max", async () => {
        await SwimmerAC.addValidators([val1, val2,val3,val4,val5, val6,val7,val8,val9,val10,val11,val12,val13,val14,val15,val16,val17,val18,val19,val20], {from: admin});

        var totalFund = new BN(1000)
        await web3.eth.sendTransaction({from: owner, to: RewardPool.address, value: totalFund})
        var rewardInfo = calculateReward(totalFund, burnRate, new BN(0), new BN(20));
        var extraTotalReward = rewardInfo.totalReward.sub(rewardInfo.totalBaseReward);
        
        var val3Stake =  maxStaked.div(new BN(2));
        var val4Stake = maxStaked;
        var totalOverStake = val3Stake.sub(minStaked).add(val4Stake.sub(minStaked));
        var val3Reward = extraTotalReward.mul(val3Stake.sub(minStaked)).div(totalOverStake).add(rewardInfo.baseReward);
        var val4Reward = extraTotalReward.mul(val4Stake.sub(minStaked)).div(totalOverStake).add(rewardInfo.baseReward);

        var tx = await RewardPool.addValidatorsStake(
            [val1, val2,val3,val4,val5, val6,val7,val8,val9,val10,val11,val12,val13,val14,val15,val16,val17,val18,val19,val20],
            [minStaked, minStaked,minStaked, minStaked,minStaked, minStaked,minStaked, minStaked,minStaked, minStaked,minStaked, minStaked,minStaked, minStaked,minStaked, minStaked,minStaked, minStaked, val3Stake, val4Stake],
            {from: owner}
        );

        await RewardPool.setStartRewardPeriod(0);
        var lastClaimedTime = await RewardPool.lastClaimedTime.call()
        await time.increase(time.duration.weeks(3));
        var tx = await RewardPool.claimReward();
        console.log('20 val gas claim: ', tx.receipt.gasUsed);

        checkClaimEvent(tx.receipt.logs[0], val1, rewardInfo.baseReward);
        checkClaimEvent(tx.receipt.logs[18], val19, val3Reward);
        checkClaimEvent(tx.receipt.logs[19], val20, val4Reward);
        checkClaimEvent(tx.receipt.logs[20], ZERO_ADDRESS, rewardInfo.burnAmount);

        console.log('claimPeriod', claimPeriod.toString());
        assert.equal(lastClaimedTime.add(claimPeriod).toString(),(await RewardPool.lastClaimedTime.call()).toString())

    })

    it("Claim reward:  1 max", async () => {
        await SwimmerAC.addValidators([val1], {from: admin});
        var newBurnRate = new BN('5000')
        var newEcoRate = new BN('1000')
        await RewardPool.changeRate(newBurnRate, newEcoRate)

        var totalFund = new BN(1000)
        await web3.eth.sendTransaction({from: owner, to: RewardPool.address, value: totalFund})
        var rewardInfo = calculateReward(totalFund, newBurnRate, newEcoRate, new BN(1));
        var extraTotalReward = rewardInfo.totalReward.sub(rewardInfo.totalBaseReward);

        var tx = await RewardPool.addValidatorsStake(
            [val1],
            [maxStaked],
            {from: owner}
        );

        await RewardPool.setStartRewardPeriod(0);
        var lastClaimedTime = await RewardPool.lastClaimedTime.call()
        await time.increase(time.duration.weeks(3));
        var tx = await RewardPool.claimReward();
        console.log('20 val gas claim: ', tx.receipt.gasUsed);

        checkClaimEvent(tx.receipt.logs[0], val1, '400');
        checkClaimEvent(tx.receipt.logs[1], ZERO_ADDRESS, rewardInfo.burnAmount);
        checkClaimEvent(tx.receipt.logs[2], ecosystemAddr, rewardInfo.ecoAmount);

        console.log('claimPeriod', claimPeriod.toString());
        assert.equal(lastClaimedTime.add(claimPeriod).toString(),(await RewardPool.lastClaimedTime.call()).toString())

    })

    it("Claim reward: only one stakes more than min", async () => {
        await SwimmerAC.addValidators([val1, val2,val3,val4,val5, val6,val7,val8,val9,val10], {from: admin});
        await RewardPool.changeRate(new BN(4000), new BN(1000));

        var totalFund = new BN(2000)
        await web3.eth.sendTransaction({from: owner, to: RewardPool.address, value: totalFund})
        var rewardInfo = calculateReward(totalFund, new BN(4000), new BN(1000), new BN(10));

        var tx = await RewardPool.addValidatorsStake(
            [val1, val2,val3,val4,val5, val6,val7,val8,val9,val10],
            [maxStaked, minStaked,minStaked, minStaked,minStaked, minStaked,minStaked, minStaked,minStaked, minStaked],
            {from: owner}
        );

        await RewardPool.setStartRewardPeriod(0);
        var lastClaimedTime = await RewardPool.lastClaimedTime.call()
        await time.increase(time.duration.weeks(3));
        var tx = await RewardPool.claimReward();

        checkClaimEvent(tx.receipt.logs[0], val1, new BN('775'));
        checkClaimEvent(tx.receipt.logs[1], val2, rewardInfo.baseReward);
        checkClaimEvent(tx.receipt.logs[9], val10, rewardInfo.baseReward);
        checkClaimEvent(tx.receipt.logs[10], ZERO_ADDRESS, rewardInfo.burnAmount);
        checkClaimEvent(tx.receipt.logs[11], ecosystemAddr, rewardInfo.ecoAmount);

        console.log('claimPeriod', claimPeriod.toString());
        assert.equal(lastClaimedTime.add(claimPeriod).toString(),(await RewardPool.lastClaimedTime.call()).toString())

    })

    it("Claim reward: all validators stake max", async () => {
        await SwimmerAC.addValidators([val1, val2,val3,val4,val5, val6,val7,val8,val9,val10], {from: admin});
        await RewardPool.changeRate(new BN(4000), new BN(1000));

        var totalFund = new BN(2000)
        await web3.eth.sendTransaction({from: owner, to: RewardPool.address, value: totalFund})
        var rewardInfo = calculateReward(totalFund, new BN(4000), new BN(1000), new BN(10));

        var tx = await RewardPool.addValidatorsStake(
            [val1, val2,val3,val4,val5, val6,val7,val8,val9,val10],
            [maxStaked, maxStaked,maxStaked, maxStaked,maxStaked, maxStaked,maxStaked, maxStaked,maxStaked, maxStaked],
            {from: owner}
        );

        await RewardPool.setStartRewardPeriod(0);
        var lastClaimedTime = await RewardPool.lastClaimedTime.call()
        await time.increase(time.duration.weeks(3));
        var tx = await RewardPool.claimReward();

        var reward = new BN(100);
        checkClaimEvent(tx.receipt.logs[0], val1, reward);
        checkClaimEvent(tx.receipt.logs[1], val2, reward);
        checkClaimEvent(tx.receipt.logs[2], val3, reward);
        checkClaimEvent(tx.receipt.logs[9], val10, reward);
        checkClaimEvent(tx.receipt.logs[10], ZERO_ADDRESS, rewardInfo.burnAmount);
        checkClaimEvent(tx.receipt.logs[11], ecosystemAddr, rewardInfo.ecoAmount);

        console.log('claimPeriod', claimPeriod.toString());
        assert.equal(lastClaimedTime.add(claimPeriod).toString(),(await RewardPool.lastClaimedTime.call()).toString())
    })

    it("Claim reward: 2 validators stake more than min", async () => {
        await SwimmerAC.addValidators([val1, val2,val3,val4,val5, val6,val7,val8,val9,val10], {from: admin});
        await RewardPool.changeRate(new BN(4000), new BN(1000));

        var totalFund = new BN(2000)
        await web3.eth.sendTransaction({from: owner, to: RewardPool.address, value: totalFund})
        var rewardInfo = calculateReward(totalFund, new BN(4000), new BN(1000), new BN(10));
        
        var val1StakeAmount = new BN('150000').mul(dec)
        var val2StakeAmount = new BN('100000').mul(dec)

        var extraTotalReward = rewardInfo.totalReward.sub(rewardInfo.totalBaseReward);
        var totalExtraStake = val1StakeAmount.add(val2StakeAmount).sub(minStaked.mul(new BN(2)));
        var va1Reward = val1StakeAmount.sub(minStaked).mul(extraTotalReward).div(totalExtraStake)
        var va2Reward = val2StakeAmount.sub(minStaked).mul(extraTotalReward).div(totalExtraStake)

        var tx = await RewardPool.addValidatorsStake(
            [val1, val2,val3,val4,val5, val6,val7,val8,val9,val10],
            [val1StakeAmount, val2StakeAmount,minStaked, minStaked,minStaked, minStaked,minStaked, minStaked,minStaked, minStaked],
            {from: owner}
        );

        await RewardPool.setStartRewardPeriod(0);
        var lastClaimedTime = await RewardPool.lastClaimedTime.call()
        await time.increase(time.duration.weeks(3));
        var tx = await RewardPool.claimReward();

        checkClaimEvent(tx.receipt.logs[0], val1, va1Reward.add(rewardInfo.baseReward));
        checkClaimEvent(tx.receipt.logs[1], val2, va2Reward.add(rewardInfo.baseReward));
        checkClaimEvent(tx.receipt.logs[2], val3, rewardInfo.baseReward);
        checkClaimEvent(tx.receipt.logs[9], val10, rewardInfo.baseReward);
        checkClaimEvent(tx.receipt.logs[10], ZERO_ADDRESS, rewardInfo.burnAmount);
        checkClaimEvent(tx.receipt.logs[11], ecosystemAddr, rewardInfo.ecoAmount);

        console.log('claimPeriod', claimPeriod.toString());
        assert.equal(lastClaimedTime.add(claimPeriod).toString(),(await RewardPool.lastClaimedTime.call()).toString())
    })

    it("Claim reward: ecosystem", async () => {
        await RewardPool.changeRate(2500, 1000);

        await SwimmerAC.addValidators([alice, bob], {from: admin});

        await web3.eth.sendTransaction({from: owner, to: RewardPool.address, value: '100'})
        var rewardInfo = calculateReward(new BN('100'), new BN(2500), new BN(1000), new BN(2));
        var tx = await RewardPool.addValidatorsStake([alice, bob], [minStaked, minStaked], {from: owner});

        await RewardPool.setStartRewardPeriod(0);
        await time.increase(time.duration.weeks(3));
        var tx = await RewardPool.claimReward();
        expectEvent(tx, 'ClaimReward', {to: alice, amount: rewardInfo.baseReward.toString()});
        expectEvent(tx, 'ClaimReward', {to: bob, amount: rewardInfo.baseReward.toString()});
        expectEvent(tx, 'ClaimReward', {to: ZERO_ADDRESS, amount: rewardInfo.burnAmount.toString()});
        expectEvent(tx, 'ClaimReward', {to: ecosystemAddr, amount: rewardInfo.ecoAmount.toString()});
    })

    it('changeClaimPeriod', async()=>{
        await expectRevert(RewardPool.changeClaimPeriod(1, {from: bob}),"Ownable: caller is not the owner");
        await RewardPool.changeClaimPeriod(10);
        assert.equal('10', (await RewardPool.claimedPeriod.call()).toString())
    })
    it('changeMinimumThreshold', async()=>{
        await expectRevert(RewardPool.changeMinimumThreshold(10, {from: bob}),"Ownable: caller is not the owner");
        await RewardPool.changeMinimumThreshold(10);
        assert.equal('10', (await RewardPool.minimumStake.call()).toString())
    })
    it('changeMaximumThreshold', async()=>{
        await RewardPool.changeMinimumThreshold(10);
        await expectRevert(RewardPool.changeMaximumThreshold(100, {from: bob}),"Ownable: caller is not the owner");
        await expectRevert(RewardPool.changeMaximumThreshold(9),"must be greater than minimum");
        await RewardPool.changeMaximumThreshold(100);
        assert.equal('100', (await RewardPool.maximumStake.call()).toString())
    })
    it('setStartRewardPeriod', async()=>{
        await expectRevert(RewardPool.setStartRewardPeriod(100, {from: bob}),"Ownable: caller is not the owner");

        await RewardPool.setStartRewardPeriod(0);
        assert.equal((await time.latest()).add(claimPeriod).toString(), (await RewardPool.lastClaimedTime.call()).toString())
        await RewardPool.setStartRewardPeriod(1);
        assert.equal('1', (await RewardPool.lastClaimedTime.call()).toString())
    })


    function calculateReward(totalFund, burningRate, ecoRate, totalValidator) {
        var burnAmount = totalFund.mul(burningRate).div(PERCENT_BASE);
        var ecoAmount = totalFund.mul(ecoRate).div(PERCENT_BASE);
        var totalReward = totalFund.sub(burnAmount).sub(ecoAmount);

        var baseReward = totalReward.mul(baseRate).div(PERCENT_BASE);
        var totalBaseReward = baseReward.mul(totalValidator);
        return{ecoAmount, burnAmount, totalReward, totalBaseReward, baseReward}
    }

    function checkClaimEvent(log, to, amount) {
        assert.equal(log.event, 'ClaimReward');
        assert.equal(log.args.to, to);
        assert.equal(log.args.amount.toString(), amount.toString());
        console.log(log.args.amount.toString(), amount.toString());
    }

})