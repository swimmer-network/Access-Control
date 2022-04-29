const SysAdmin = artifacts.require("SysAdmin");
const SysAdminProxy = artifacts.require("SysAdminProxy");
const NativeMinter = artifacts.require("NativeMinter");
const WTUS = artifacts.require("WTUS");

const balance = require('@openzeppelin/test-helpers/src/balance');
const expectEvent = require('@openzeppelin/test-helpers/src/expectEvent');
const expectRevert = require('@openzeppelin/test-helpers/src/expectRevert');
const { assert } = require('chai');
// const { web3 } = require('@openzeppelin/test-helpers/src/setup');


contract("WTUS", async ([owner, admin, alice, bob]) => {
    var nativeMinterContract;
    var deployerContract;
    var sa;
    var wtus;
    beforeEach(async()=>{
        nativeMinterContract = await NativeMinter.new();
        deployerContract = await NativeMinter.new();
        var saLogic = await SysAdmin.new();
        var saProxy = await SysAdminProxy.new(saLogic.address, admin);
        sa = await SysAdmin.at(saProxy.address);
        await sa.initialize(nativeMinterContract.address, deployerContract.address);

        await sa.setAdmin(owner, true);
        await web3.eth.sendTransaction({from: owner, to: nativeMinterContract.address, value: '1000000000'});

        wtus = await WTUS.new(sa.address);
        sa.setMinter(wtus.address, true);
    });

    it("Mint token", async () => {
        // not miner can not mint
        await expectRevert(wtus.mint(alice, '1', {from: bob}), "TUS: Only minter");

        // mint by minter
        await wtus.setMinter(bob, true);
        var aliceBalance = await balance.tracker(alice)
        var tx = await wtus.mint(alice, '1', {from: bob});
        await expectEvent.inTransaction(tx.receipt.transactionHash, sa.contract, 'Mint', {minter: wtus.address, to: alice, amount: '1'});


        assert.equal('1', (await aliceBalance.delta()).toString());
        var tx = await wtus.mint(alice, '2', {from: bob});
        
        await expectEvent.inTransaction(tx.receipt.transactionHash, sa.contract, 'Mint', {minter: wtus.address, to: alice, amount: '2'});

        assert.equal('2', (await aliceBalance.delta()).toString());

    })

    it("Deposit", async () => {
        // by calling deposit
        var tx = await wtus.deposit({from: bob, value: 1});
        expectEvent(tx, 'Deposit', {dst: bob, amount: '1'});
        
        assert('1', (await wtus.balanceOf.call(bob)).toString())
        assert('1', (await wtus.balanceOf.call(bob)).toString())
        
        // by sent money to contract
        var tx = await web3.eth.sendTransaction({from: bob, to: wtus.address, value: '2'});
        await expectEvent.inTransaction(tx.transactionHash, wtus.contract, 'Deposit', {dst: bob, amount: '2'})
        assert('3', (await wtus.balanceOf.call(bob)).toString())
    })

    it("Withdraw", async () => {
        // deposit
        var tx = await wtus.deposit({from: bob, value: '100'});
        expectEvent(tx, 'Deposit', {dst: bob, amount: '100'});

        // balance too small
        await expectRevert(wtus.withdraw('1000', {from: bob}), "WTUS: insufficient balance");

        // withdraw
        var bobBalance = await balance.tracker(bob)
        var tx = await wtus.withdraw('50', {from: bob, gasPrice: 0});
        await expectEvent.inTransaction(tx.receipt.transactionHash, sa.contract, 'Mint', {to: bob, amount: '50'})

        assert.equal('50', (await bobBalance.delta()).toString());
        assert.equal('50', (await wtus.balanceOf.call(bob)))

    })


    it("Set minter", async () => {
        // can not set if caller is not owner
        await expectRevert(wtus.setMinter(alice, true, {from: bob}), "Ownable: caller is not the owner");

        // set by admin
        var tx= await wtus.setMinter(bob, true);
        assert.equal('true', (await wtus.minters.call(bob)).toString());
        expectEvent(tx, 'SetMinter', {addr: bob, status: true});

        var tx = await wtus.setMinter(bob, false);
        expectEvent(tx, 'SetMinter', {addr: bob, status: false});
        assert.equal('false', (await wtus.minters.call(bob)).toString());
    })
    it("setNativeMinterContract", async () => {
        // can not set if caller is not owner
        await expectRevert(wtus.setNativeMinterContract(alice, {from: bob}), "Ownable: caller is not the owner");

        // set by admin
        var tx= await wtus.setNativeMinterContract(bob);
        assert.equal(bob, (await wtus.nativeMinter.call()).toString());
        
    })

})