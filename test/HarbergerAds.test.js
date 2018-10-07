var utils = require('web3-utils')
var HarbergerAds = artifacts.require('./HarbergerAds.sol')
var ERC20test = artifacts.require('./ERC20test.sol')

let gasPrice = 1000000000 // 1GWEI

let _ = '        '

contract('HarbergerAds', async function(accounts) {
  let harbergerAds, _ERC20test

  before(done => {
    ;(async () => {
      try {
        _ERC20test = await ERC20test.new()
        await _ERC20test.mint(accounts[0], '1000000000000000000000')

        // Deploy HarbergerAds.sol
        harbergerAds = await HarbergerAds.new(_ERC20test.address, 50000000000, 1000000000000)
        console.log(harbergerAds.address)

        done()
      } catch (error) {
        console.error(error)
        done(false)
      }
    })()
  })

  describe('HarbergerAds.sol', function() {
    it('should make, buy and tax property', async function() {
      try {
        await _ERC20test.approve(harbergerAds.address, '1000000000000000000000000000')
        await harbergerAds.addProperty('100000000000000000000')
        // await harbergerAds.buy(0, '100000000000000000000', '100000000000000000000')
        // await increaseTime(1000)
        // await harbergerAds.collectTaxes(0)
      }catch (error) {
        console.error(error)
        assert(false, 'error occurred')
      }
    })

  })
})

function getBlockNumber() {
  return new Promise((resolve, reject) => {
    web3.eth.getBlockNumber((error, result) => {
      if (error) reject(error)
      resolve(result)
    })
  })
}

function increaseBlocks(blocks) {
  return new Promise((resolve, reject) => {
    increaseBlock().then(() => {
      blocks -= 1
      if (blocks == 0) {
        resolve()
      } else {
        increaseBlocks(blocks).then(resolve)
      }
    })
  })
}

function increaseBlock() {
  return new Promise((resolve, reject) => {
    web3.currentProvider.sendAsync(
      {
        jsonrpc: '2.0',
        method: 'evm_mine',
        id: 12345
      },
      (err, result) => {
        if (err) reject(err)
        resolve(result)
      }
    )
  })
}

function increaseTime(amount) {
  return new Promise((resolve, reject) => {
    web3.currentProvider.sendAsync(
      {
        jsonrpc: '2.0',
        method: 'evm_increaseTime',
        params: [amount],
        id: new Date().getSeconds()
      },
      (err, result) => {
        if (err) {reject(err)}
        else {
          if (!err) {
            web3.currentProvider.sendAsync({
              jsonrpc: '2.0',
              method: 'evm_mine',
              params: [],
              id: new Date().getSeconds()
            }, (err, result) => {
              if (err) reject(err)
              resolve(result)
            })
          }
        }
      }
    )
  })
}

function decodeEventString(hexVal) {
  return hexVal
    .match(/.{1,2}/g)
    .map(a =>
      a
        .toLowerCase()
        .split('')
        .reduce(
          (result, ch) => result * 16 + '0123456789abcdefgh'.indexOf(ch),
          0
        )
    )
    .map(a => String.fromCharCode(a))
    .join('')
}
