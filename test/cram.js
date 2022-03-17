const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
  time,
} = require("@openzeppelin/test-helpers");

const CRAM = artifacts.require("CRAM");
const CRAMUpgradeable = artifacts.require("CRAMUpgradeable");
var cram;
contract("CRAM: ", async ([owner, admin, alice, bob, dave, carol, feeAddress1, feeAddress2, operator]) => {
    beforeEach("", async () => {
        var cramLogic = await CRAM.new();
        var cramProxy = await CRAMUpgradeable.new(cramLogic.address, admin, "0x");
        cram = await CRAM.at(cramProxy.address);
        await cram.initialize(owner);
    });

    it("Minter ", async () => {
        await expectRevert(cram.mint(alice, 10, {from: alice}), "CRAM: Only minter");
        await cram.mint(alice, 10);
        assert.equal('10', (await cram.balanceOf.call(alice)).toString());
    });

    it("Transfer: always failed", async () => {
        await cram.mint(alice, 10);
        await expectRevert(cram.transfer(bob, 1, {from: alice}), "CRAM: not allow to transfer");
    });

    it("Transfer from ", async () => {
        // Sender & receiver are not in whitelist
        await cram.mint(alice, 10);
        await cram.approve(bob, 10, {from: alice});
        await expectRevert(cram.transferFrom(alice, dave, 1, {from: bob}), "CRAM: not in whitelist");
        
        // ok if sender is in whitelist
        await cram.setSenderWhitelist(alice, true);
        var tx = await cram.transferFrom(alice, dave, 1, {from: bob});
        expectEvent(tx, "Transfer", {from: alice, to: dave});
        
        // ok if receiver is in whitelist
        await cram.setSenderWhitelist(alice, false);
        await cram.setReceipientWhitelist(dave, true);
        var tx = await cram.transferFrom(alice, dave, 1, {from: bob});
        expectEvent(tx, "Transfer", {from: alice, to: dave});
    });

    it.only("Set whitelist ", async () => {
        // Only owner
        await expectRevert(cram.setSenderWhitelist(alice, true, {from: bob}), "Ownable: caller is not the owner");
        await expectRevert(cram.setReceipientWhitelist(alice, true, {from: bob}), "Ownable: caller is not the owner");

        // Set whitelist successful
        await cram.setSenderWhitelist(alice, true);
        await cram.setReceipientWhitelist(dave, true);

        assert.equal(true, (await cram.senderWhitelist.call(alice)));
        assert.equal(true, (await cram.receipientWhitelist.call(dave)));

        await cram.setSenderWhitelist(alice, false);
        await cram.setReceipientWhitelist(dave, false);

        assert.equal(false, (await cram.senderWhitelist.call(alice)));
        assert.equal(false, (await cram.receipientWhitelist.call(dave)));
    });

});
