const Cifi_Token = artifacts.require("Cifi_Token");
const Multi_Signature=artifacts.require("Multi_Signature");

module.exports = async function (deployer) {

  const accounts = await web3.eth.getAccounts();
  const multiSigAccount = accounts[0];
  console.log(multiSigAccount);
  deployer.deploy(Cifi_Token,multiSigAccount);
  deployer.deploy(Multi_Signature);
};
