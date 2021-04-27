const Cifi_Token = artifacts.require("Cifi_Token");
const Multi_Signature=artifacts.require("Multi_Signature");

module.exports = function (deployer) {
  deployer.deploy(Cifi_Token);
  deployer.deploy(Multi_Signature);
};
