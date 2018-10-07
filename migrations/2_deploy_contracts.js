var ERC20test = artifacts.require('./ERC20test.sol')
var HarbergerAds = artifacts.require('./HarbergerAds.sol')
let _ = '        '

module.exports = (deployer, network, accounts) => {

  deployer.then(async () => {
    try {
      let _ERC20test
      if (network === 'ganache' || network === 'rinkeby' || network === 'parity' || network === 'rinkeby-fork') {
        // Deploy HarbergerAds.sol
        await deployer.deploy(ERC20test)
        _ERC20test = await ERC20test.deployed()
        console.log(_ + 'ERC20test deployed at: ' + _ERC20test.address)
        await _ERC20test.mint(accounts[0], {value:'100000000000000000'})
      } else if (network === 'mainnet'){
        _ERC20test.address = '0x0' // dai address here
      } else {
        console.log('network is ' + network)
      }

        // Deploy HarbergerAds.sol
        await deployer.deploy(HarbergerAds, _ERC20test.address, 50000000000, 1000000000000)
        let harbergerAds = await HarbergerAds.deployed()
        console.log(_ + 'HarbergerAds deployed at: ' + harbergerAds.address)

    } catch (error) {
      console.log(error)
    }
  })
}
