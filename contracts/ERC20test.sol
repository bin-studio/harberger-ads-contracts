pragma solidity ^0.4.24;
import 'zeppelin-solidity/contracts/token/ERC20/MintableToken.sol';
import 'zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol';
import 'zeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol';

contract ERC20test is DetailedERC20('TEST', 'TST', 18), MintableToken, BurnableToken {
    modifier hasMintPermission() {
      _;
    }
    function() public payable {}

    function burn(uint256 _value) public {
      _burn(msg.sender, _value);
      msg.sender.transfer(_value);
    }

    function mint(
      address _to
    )
      public
      payable
      hasMintPermission
      canMint
      returns (bool)
    {
      this.transfer(msg.value);
      totalSupply_ = totalSupply_.add(msg.value);
      balances[_to] = balances[_to].add(msg.value);
      emit Mint(_to, msg.value);
      emit Transfer(address(0), _to, msg.value);
      return true;
    }
}
