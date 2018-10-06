var HarbergerAds = artifacts.require('./HarbergerAds.sol')
let _ = '        '

module.exports = (deployer, helper, accounts) => {

  deployer.then(async () => {
    try {
      // Deploy HarbergerAds.sol
      await deployer.deploy(HarbergerAds, 10, 5, 100)
      let harbergerAds = await HarbergerAds.deployed()
      console.log(_ + 'HarbergerAds deployed at: ' + harbergerAds.address)

    } catch (error) {
      console.log(error)
    }
  })
}
