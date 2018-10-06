pragma solidity ^0.4.24;
import 'zeppelin-solidity/contracts/token/ERC20/MintableToken.sol';
import 'zeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol';

contract ERC20test is DetailedERC20('TEST', 'TST', 18), MintableToken {
    modifier hasMintPermission() {
      _;
    }
}
