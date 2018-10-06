pragma solidity ^0.4.24;
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

contract HarbergerAds is Ownable {
    // Per day tax rate
    uint32 public taxNumerator;
    uint32 public taxDenominator;

    struct Property {
        address taxRecipient;
        address owner;
        uint96 price;
    }

    Property[] public properties;

    constructor(
        uint32 _taxNumerator,
        uint32 _taxDenominator
    ) public {
        taxNumerator = _taxNumerator;
        taxDenominator = _taxDenominator;
    }

    struct Account {
        uint256 balance;
        uint144 sumOfPrices;
        uint112 paidThru;
    }

    mapping(address => Account) public accounts;

    function taxesDue(address addr) public view returns (uint256) {
        Account storage a = accounts[addr];

        return a.sumOfPrices * (now - a.paidThru) * taxNumerator
            / taxDenominator / 1 days;
    }

    event Change(uint256 indexed id, address indexed to, address indexed from);

    function addProperty(address receiver) public {

    }

    // Possibly foreclose on property[id]
    function forecloseIfPossible(uint256 id) public {
        Property storage p = properties[id];
        Account storage a = accounts[p.owner];

        // Owner must be broke and behind on taxes to foreclose
        if (a.balance == 0 && a.paidThru < now && a.sumOfPrices > 0) {
            a.sumOfPrices -= p.price;
            emit Change(id, 0, p.owner);
            delete(properties[id]);
        }
    }

    event TaxesPaid(address owner, uint256 paid);
    // Collect taxes due from account.
    // Return true if taxes fully paid, false otherwise
    function collectTaxes(address addr) public returns (bool) {
        Account storage a = accounts[addr];

        uint256 taxes = taxesDue(addr);
        if (taxes <= a.balance) {
            a.paidThru = uint112(now);
            accounts[a.taxRecipient].balance += taxes;
            a.balance -= taxes;
            emit TaxesPaid(addr, taxes);
            return true;
        } else {
            // Adjust paidThru proportionally (overflow check unnecessary)
            a.paidThru += uint112((now - a.paidThru) * a.balance / taxes);

            // Collect entire balance for partially-paid taxes
            accounts[a.taxRecipient].balance += a.balance;
            emit TaxesPaid(addr, a.balance);
            a.balance = 0;
            return false;
        }
    }

    // Try to buy property for no more than 'max'
    function buy(
        uint256 id,
        uint256 max,
        uint96 price
    )
        public
        payable
    {
        accounts[msg.sender].balance += msg.value;

        Property storage p = properties[id];

        // Collect taxes from property's owner and possibly foreclose on property[id].
        collectTaxes(p.owner);

        // Foreclosure may change price and seller.
        forecloseIfPossible(id);
        address seller = p.owner;

        if (seller != msg.sender) {
            require(max >= p.price, "price is too high");

            // Collect taxes due from buyer before checking their balance
            collectTaxes(msg.sender);
            require(accounts[msg.sender].balance >= p.price,
                "insufficient funds");

            // Transfer purchase price
            accounts[seller].balance += p.price;
            accounts[msg.sender].balance -= p.price;

            p.owner = msg.sender;
        }
        // Adjust buyer's and seller's sumOfPrices
        accounts[seller].sumOfPrices -= p.price;
        accounts[msg.sender].sumOfPrices += price;

        p.price = price;

        emit Change(id, msg.sender, seller);
    }

    function deposit() public payable {
        accounts[msg.sender].balance += msg.value;
    }

    function withdraw(uint256 amount) public {
        collectTaxes(msg.sender);

        require(accounts[msg.sender].balance >= amount, "insufficient funds");

        accounts[msg.sender].balance -= amount;
        msg.sender.transfer(amount);
    }

    function propertyCount() public view returns (uint256) {
        return properties.length;
    }

    address public newRecipient;

    function approveRecipient(uint256 id, address _newRecipient) public {
        require(msg.sender == properties[id].taxRecipient, "must be taxRecipient");
        newRecipient = _newRecipient;
    }

    function transferRecipient() public {
        require(msg.sender == newRecipient, "must be approved");
        taxRecipient = msg.sender;
        newRecipient = 0;
    }
}
