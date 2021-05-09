const Cifi_Token = artifacts.require("Cifi_Token");

module.exports = async function (deployer) {
  deployer.deploy(Cifi_Token);
};
