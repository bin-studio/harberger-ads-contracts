pragma solidity ^0.4.24;

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: contracts/HarbergerAds.sol

contract HarbergerAds is Ownable {
    // Per day tax rate
    uint256 public taxNumerator;
    uint256 public taxDenominator;

    ERC20 public erc20;

    struct Property {
        address taxRecipient;
        address owner;
        uint256 price;
        uint256 paidThru;
    }

    Property[] public properties;

    constructor(
        ERC20 erc20Address,
        uint256 _taxNumerator,
        uint256 _taxDenominator
    ) public {
        taxNumerator = _taxNumerator;
        taxDenominator = _taxDenominator;
        erc20 = erc20Address;
    }

    function taxesDue(uint256 id) public view returns (uint256) {
        Property storage p = properties[id];

        return p.price * (now - p.paidThru) * taxNumerator
            / taxDenominator / 1 days;
    }

    function balanceOf(address user) public constant returns (uint256) {
        uint256 balance = erc20.balanceOf(user);
        uint256 allowance = erc20.allowance(user, this);
        if (balance > allowance) {
            return allowance;
        } else {
            return balance;
        }
    }

    event Change(uint256 indexed id, address indexed to, address indexed from, uint256 price);
    event ChangeRecipient(uint256 indexed id, address indexed to, address indexed from);
    event TaxesPaid(uint256 indexed id, address owner, uint256 paid);

    function addProperty(uint256 price) public {
        Property memory p;
        p.owner = msg.sender;
        p.taxRecipient = msg.sender;
        p.price = price;
        uint256 id = properties.push(p) - 1;
        emit Change(id, msg.sender, 0, price);
    }

    // Possibly foreclose on property[id]
    function forecloseIfPossible(uint256 id) public {
        Property storage p = properties[id];
        // Owner must be broke and behind on taxes to foreclose
        if (p.owner != p.taxRecipient && balanceOf(p.owner) == 0 && p.paidThru < now && p.price > 0) {
            emit Change(id, 0, p.owner, 0);
            delete(properties[id]);
        }
    }

    // Collect taxes due from account.
    // Return true if taxes fully paid, false otherwise
    function collectTaxes(uint256 id) public returns (bool) {
        Property storage p = properties[id];
        if (p.owner == p.taxRecipient) {
            p.paidThru = uint256(now);
            return true;
        }
        uint256 balance = balanceOf(p.owner);
        uint256 taxes = taxesDue(id);
        if (taxes <= balance) {
            p.paidThru = uint256(now);
            if (taxes > 0) {
                require(erc20.transferFrom(p.owner, p.taxRecipient, taxes), 'transferFrom failed');
            }
            emit TaxesPaid(id, p.owner, taxes);
            return true;
        } else {
            // Adjust paidThru proportionally (overflow check unnecessary)
            p.paidThru += uint256((now - p.paidThru) * balance / taxes);

            // Collect entire balance for partially-paid taxes
            if (balance > 0) {
                require(erc20.transferFrom(p.owner, p.taxRecipient, balance), 'transferFrom failed');
            }
            emit TaxesPaid(id, p.owner, balance);
            return false;
        }
    }

    // Try to buy property for no more than 'max'
    function buy(
        uint256 id,
        uint256 max,
        uint256 price
    )
        public
    {
        Property storage p = properties[id];

        // Collect taxes from property's owner and possibly foreclose on property[id].
        collectTaxes(id);

        // Foreclosure may change price and seller.
        forecloseIfPossible(id);
        address seller = p.owner;

        if (seller != msg.sender) {
            require(max >= p.price, "price is too high");

            require(balanceOf(msg.sender) >= p.price,
                "insufficient funds");

            // Transfer purchase price
            if (p.price > 0) {
                require(erc20.transferFrom(p.owner, seller, p.price), 'transferFrom failed');
            }
            p.owner = msg.sender;
        }

        p.price = price;
        emit Change(id, msg.sender, seller, price);
    }

    function propertyCount() public view returns (uint256) {
        return properties.length;
    }

    function changeRecipient(uint256 id, address newRecipient) public {
        require(msg.sender == properties[id].taxRecipient, "must be previous taxRecipient");
        properties[id].taxRecipient = newRecipient;
        emit ChangeRecipient(id, newRecipient, msg.sender);
    }

}
