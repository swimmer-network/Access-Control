const SysAdmin = artifacts.require("SysAdmin");
const SysAdminProxy = artifacts.require("SysAdminProxy");
const NativeMinter = artifacts.require("NativeMinter");



const balance = require('@openzeppelin/test-helpers/src/balance');
const expectEvent = require('@openzeppelin/test-helpers/src/expectEvent');
const expectRevert = require('@openzeppelin/test-helpers/src/expectRevert');
const { assert } = require('chai');
// const { web3 } = require('@openzeppelin/test-helpers/src/setup');


contract("SysAdmin", async ([owner, admin, alice, bob]) => {
    var nativeMinterContract;
    var deployerContract;
    var sa;
    beforeEach(async()=>{
        nativeMinterContract = await NativeMinter.new();
        deployerContract = await NativeMinter.new();
        var saLogic = await SysAdmin.new();
        var saProxy = await SysAdminProxy.new(saLogic.address, admin);
        sa = await SysAdmin.at(saProxy.address);
        await sa.initialize(nativeMinterContract.address, deployerContract.address);

        await sa.setAdmin(owner, true);
        await web3.eth.sendTransaction({from: owner, to: nativeMinterContract.address, value: '1000000000'});
    });

    it("Mint token", async () => {
        // not miner can not mint
        await expectRevert(sa.mint(alice, '1', {from: bob}), "SA: not minter");
        await expectRevert(sa.mintNativeCoin(alice, '1', {from: bob}), "SA: not minter");

        // mint by minter
        await sa.setMinter(bob, true);
        var aliceBalance = await balance.tracker(alice)
        var tx = await sa.mint(alice, '1', {from: bob});
        expectEvent(tx, 'Mint', {minter: bob, to: alice, amount: '1'});
        assert.equal('1', (await aliceBalance.delta()).toString());
        var tx = await sa.mintNativeCoin(alice, '2', {from: bob});
        expectEvent(tx, 'Mint', {minter: bob, to: alice, amount: '2'});
        assert.equal('2', (await aliceBalance.delta()).toString());

    })

    it("Set deployer", async () => {
        // can not set if caller is not admin
        await expectRevert(sa.setContractDeployer(alice, true, {from: bob}), "SA: not admin");

        // set by admin
        await sa.setAdmin(bob, true);
        var tx = await sa.setContractDeployer(alice, true, {from: bob});
        expectEvent(tx, 'SetContractDeployer', {addr: alice, isEnabled: true});
        assert.equal('1', (await deployerContract.readAllowList.call(alice)).toString());

        var tx = await sa.setContractDeployer(alice, false, {from: bob});
        expectEvent(tx, 'SetContractDeployer', {addr: alice, isEnabled: false});
        assert.equal('0', (await deployerContract.readAllowList.call(alice)).toString());
    })

    
    it("Set minter", async () => {
        // can not set if caller is not admin
        await expectRevert(sa.setMinter(alice, true, {from: bob}), "SA: not admin");

        // set by admin
        await sa.setAdmin(bob, true);
        var tx = await sa.setMinter(alice, true, {from: bob});
        expectEvent(tx, 'SetMinter', {addr: alice, isEnabled: true});
        assert.equal('true', (await sa.checkMinter.call(alice)).toString());
        var tx = await sa.setMinter(alice, false, {from: bob});
        expectEvent(tx, 'SetMinter', {addr: alice, isEnabled: false});
        assert.equal('false', (await sa.checkMinter.call(alice)).toString());
    })

    it("Set admin", async () => {
        // can not set if caller is not admin
        await expectRevert(sa.setAdmin(alice, true, {from: bob}), "Ownable: caller is not the owner");

        // set by admin
        var tx = await sa.setAdmin(alice, true);
        expectEvent(tx, 'SetAdmin', {addr: alice, isEnabled: true});
        assert.equal('true', (await sa.checkAdmin.call(alice)).toString());
        
        var tx = await sa.setAdmin(alice, false);
        expectEvent(tx, 'SetAdmin', {addr: alice, isEnabled: false});
        assert.equal('false', (await sa.checkAdmin.call(alice)).toString());

        
    })
    // contractDeployerAddress, address nativeMinterAddress
    it("changeNativeMinterAddress", async () => {
        await expectRevert(sa.changeNativeMinterAddress(alice, {from: bob}), "Ownable: caller is not the owner");
        await sa.changeNativeMinterAddress(bob);
        assert.equal(bob, (await sa.getContractAddresses.call()).nativeMinterAddress)
    })
    it("changeContractDeployerAddress", async () => {
        await expectRevert(sa.changeContractDeployerAddress(alice, {from: bob}), "Ownable: caller is not the owner");
        await sa.changeContractDeployerAddress(bob);
        assert.equal(bob, (await sa.getContractAddresses.call()).contractDeployerAddress)
    })


})