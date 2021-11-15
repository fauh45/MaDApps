const MaDApps = artifacts.require("MaDApps");

module.exports = function (deployer) {
    deployer.deploy(MaDApps);
};