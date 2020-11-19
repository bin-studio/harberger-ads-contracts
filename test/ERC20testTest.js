const truffleAssert = require('truffle-assertions');
const ERC20test = artifacts.require('ERC20test');
const HarbergerAds = artifacts.require('HarbergerAds');
const SafeMath = artifacts.require(
  'zeppelin-solidity/contracts/math/SafeMath.sol',
);
const Ownable = artifacts.require(
  'zeppelin-solidity/contracts/ownership/Ownable.sol',
);
const BasicToken = artifacts.require(
  'zeppelin-solidity/contracts/token/ERC20/BasicToken.sol',
);
const BurnableToken = artifacts.require(
  'zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol',
);
const DetailedERC20 = artifacts.require(
  'zeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol',
);
const MintableToken = artifacts.require(
  'zeppelin-solidity/contracts/token/ERC20/MintableToken.sol',
);
const StandardToken = artifacts.require(
  'zeppelin-solidity/contracts/token/ERC20/StandardToken.sol',
);

contract('ERC20test', (accounts) => {
  let contractSafeMath = null;
  let contractERC20test = null;

  beforeEach(async () => {
    contractSafeMath = await SafeMath.new({from: accounts[0]});
    BasicToken.link('SafeMath', contractSafeMath.address);
    contractBasicToken = await BasicToken.new({from: accounts[0]});
    contractBurnableToken = await BurnableToken.new({from: accounts[0]});
    contractMintableToken = await MintableToken.new({from: accounts[0]});
    contractStandardToken = await StandardToken.new({from: accounts[0]});
    contractOwnable = await Ownable.new({from: accounts[0]});
    contractERC20test = await ERC20test.new({from: accounts[0]});
    contractHarbergerAds = await HarbergerAds.new(
      contractERC20test.address,
      1331007096,
      29,
      {from: accounts[0]},
    );
  });

  it('Should fail mint(address) when NOT comply with: mintingFinished != true', async () => {
    let localERC20test = await ERC20test.new({from: accounts[0]});
    await localERC20test.finishMinting({from: accounts[0]});
    let result = await truffleAssert.fails(
      localERC20test.methods['mint(address)'](accounts[6], {from: accounts[0]}),
      'revert',
    );
  });
});
