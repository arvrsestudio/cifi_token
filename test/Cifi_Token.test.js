const Cifi_Token = artifacts.require("./Cifi_Token");

require("chai").use(require("chai-as-promised")).should();

contract("Cifi_Token", ([deployer, receiver, exchange]) => {
  const EVM_REVERT = "VM Exception while processing transaction: revert";
  const name = "Ciphi";
  const symbol = "CIFI";
  const decimals = "18";
  const totalSupply = "0";

  let cifi_Token;

  beforeEach(async () => {
    cifi_Token = await Cifi_Token.new(deployer);
  });

  describe("deployment", () => {
    it("tracks the name: Ciphi", async () => {
      const result = await cifi_Token.name();
      result.should.equal(name);
    });

    it("tracks the symbol: CIFI", async () => {
      const result = await cifi_Token.symbol();
      result.should.equal(symbol);
    });

    it("tracks the decimals: 18", async () => {
      const result = await cifi_Token.decimals();
      result.toString().should.equal(decimals);
    });

    it("tracks the total supply: 0", async () => {
      const result = await cifi_Token.totalSupply();
      result.toString().should.equal(totalSupply);
    });

    it("assigns the total supply to the deployer: 0", async () => {
      const result = await cifi_Token.balanceOf(deployer);
      result.toString().should.equal(totalSupply);
    });
  });

  describe("sending tokens", () => {
    let result;
    let minting;
    let amount;
    let mintedAmount;

    describe("success", async () => {
      beforeEach(async () => {
        amount = "100000000000000000000";
        mintedAmount = "500";
        remainingAmount = "300000000000000000000";
        minting = await cifi_Token.mint(deployer, mintedAmount);
        result = await cifi_Token.transfer(receiver, amount);
        amountBurned = "100";
        await cifi_Token.burn(amountBurned);
      });

      it("transfers token balances", async () => {
        let balanceOf;
        balanceOf = await cifi_Token.balanceOf(deployer);
        balanceOf.toString().should.equal(remainingAmount);
        balanceOf = await cifi_Token.balanceOf(receiver);
        balanceOf.toString().should.equal(amount);
      });

      

      it("emits a Transfer event", async () => {
        const log = result.logs[0];
        log.event.should.eq("Transfer");
        const event = log.args;
        event.from.toString().should.equal(deployer, "deployer is Not correct");
        event.to.should.equal(receiver, "receiver is Not correct");
        event.value
          .toString()
          .should.equal(amount.toString(), "value is Not correct");
      });
    });
    describe("failure", async () => {
      it("rejects insufficient balances", async () => {
        let invalidAmount;
        invalidAmount = "5000000000000000000000000"; // 5,000,000  - greater than total supply
        await cifi_Token
          .transfer(receiver, invalidAmount)
          .should.be.rejectedWith(EVM_REVERT);

        // Attempt transfer tokens, when you have none
        invalidAmount = "10"; // recipient has no tokens
        await cifi_Token
          .transfer(deployer, invalidAmount, {
            from: receiver,
          })
          .should.be.rejectedWith(EVM_REVERT);
      });

      it("rejects invalid recipients", async () => {
        await cifi_Token.transfer(0x0, amount, { from: deployer }).should.be
          .rejected;
      });
    });
  });

  describe("approving tokens", () => {
    let result;
    let amount;

    beforeEach(async () => {
      amount = "100000000000000000000";
      result = await cifi_Token.approve(exchange, amount, { from: deployer });
    });

    describe("success", () => {
      it("allocates an allowance for delegated token spending on exchange", async () => {
        const allowance = await cifi_Token.allowance(deployer, exchange);
        allowance.toString().should.equal(amount);
      });

      it("emits an Approval event", async () => {
        const log = result.logs[0];
        log.event.should.eq("Approval");
        const event = log.args;
        event.owner.toString().should.equal(deployer, "owner is Not correct");
        event.spender.should.equal(exchange, "spender is Not correct");
        event.value.toString().should.equal(amount, "value is Not correct");
      });
    });

    describe("failure", () => {
      it("rejects invalid spenders", async () => {
        await cifi_Token.approve(0x0, amount, { from: deployer }).should.be
          .rejected;
      });

      it("rejects minting more than the max supply", async () => {
        mintedAmount = "5000000";
        await cifi_Token.mint(deployer, mintedAmount).should.be
          .rejected;
      });
    });
  });

  describe("delegated token transfers", () => {
    let result;
    let amount;
    let minting;
    let mintedAmount = "500";

    beforeEach(async () => {
      amount = "100000000000000000000";

      minting = await cifi_Token.mint(deployer, mintedAmount);
      await cifi_Token.approve(exchange, amount, { from: deployer });
    });
    describe("success", async () => {
      beforeEach(async () => {
        result = await cifi_Token.transferFrom(deployer, receiver, amount, {
          from: exchange,
        });
      });

      it("transfers token balances", async () => {
        let balanceOf;
        balanceOf = await cifi_Token.balanceOf(deployer);
        balanceOf.toString().should.equal("400000000000000000000".toString());
        balanceOf = await cifi_Token.balanceOf(receiver);
        balanceOf.toString().should.equal("100000000000000000000".toString());
      });

      it("resets the allowance", async () => {
        const allowance = await cifi_Token.allowance(deployer, exchange);
        allowance.toString().should.equal("0");
      });

      it("emits a Transfer event", async () => {
        const log = result.logs[0];
        log.event.should.eq("Transfer");
        const event = log.args;
        event.from.toString().should.equal(deployer, "from is correct");
        event.to.should.equal(receiver, "to is correct");
        event.value.toString().should.equal(amount, "value is correct");
      });
    });

    describe("failure", async () => {
      it("rejects insufficient amounts", async () => {
        // Attempt transfer too many tokens
        const invalidAmount = "800000000000000000000";
        await cifi_Token
          .transferFrom(deployer, receiver, invalidAmount, { from: exchange })
          .should.be.rejectedWith(EVM_REVERT);
      });

      it("rejects invalid recipients", async () => {
        await cifi_Token.transferFrom(deployer, 0x0, amount, { from: exchange })
          .should.be.rejected;
      });
    });
  });

  describe("activating the Pause function and testing", async () => {
    beforeEach(async () => {
      let minting;

      minting = await cifi_Token.mint(deployer, "500");

      await cifi_Token.pause();

      let result;
      let amount;
      let mintedAmount;
      amount = "100000000000000000000";
    });

    it("should reject minting becuase its pasued", async () => {
      mintedAmount = "500";
      await cifi_Token.mint(deployer, mintedAmount).should.be.rejected;
    });

    it("should reject transferring becuase its pasued", async () => {
      amount = "100000000000000000000";

      await cifi_Token.transfer(receiver, amount).should.be.rejected;
    });

    it("should reject burn becuase its pasued", async () => {
      amount = "100000000000000000000";

      await cifi_Token.burn(amount).should.be.rejected;
    });

    it("should reject transferFrom becuase its pasued", async () => {
      let result;
      amount = "100000000000000000000";
      result = await cifi_Token.approve(exchange, amount, { from: deployer });
      result = await cifi_Token.transferFrom(deployer, receiver, amount, {
        from: exchange,
      }).should.be.rejected;
    });

    it("unpasue again and retest to make sure MINT works again", async () => {
      await cifi_Token.unpause();
      mintedAmount = "100";
      await cifi_Token.mint(deployer, mintedAmount);
    });

    it("unpasue again and retest to make sure BURN works again", async () => {
      await cifi_Token.unpause();
      amount = "100";
      await cifi_Token.burn(amount);
    });

    it("unpasue again and retest to make sure TRANSFER works again", async () => {
      await cifi_Token.unpause();
      amount = "100000000000000000000";
      await cifi_Token.transfer(receiver, amount);
    });

    it("unpasue again and retest to make sure TRANSFERFROM works again", async () => {
      await cifi_Token.unpause();
      let result;
      amount = "100000000000000000000";
      result = await cifi_Token.approve(exchange, amount, { from: deployer });
      result = await cifi_Token.transferFrom(deployer, receiver, amount, {
        from: exchange,
      });
    });
  });
});
