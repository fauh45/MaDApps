const ODAOToken = artifacts.require("ODAOToken");
const ODAOIdentity = artifacts.require("ODAOIdentity");

module.exports = async function (deployer, network, accounts) {
    await deployer.deploy(ODAOToken);
    const ODAOTokenInstance = await ODAOToken.deployed();

    await deployer.deploy(ODAOIdentity, ODAOTokenInstance.address, 1_000);
};