pragma solidity 0.8.1;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/Context.sol";

import "./IBEP20.sol";
import "./ReentrancyGuard.sol";


contract WeentarPresale is Context, Ownable, ReentrancyGuard {

    IBEP20 private _token;
    address private _wallet;
    mapping(uint256 => uint256) _weiRaised;

    // phase detail
    uint256 private _tokenPrice;
    uint256 private _phaseSupplyLeft;
    uint256 private _phaseSupplyTotal;
    uint256 private _phaseStartTimestamp; //epoch in seconds
    uint256 private _phaseEndTimestamp; //epoch in seconds

    constructor(address token, address wallet) {
        _token = IBEP20(token);
        _wallet = wallet;
    }

    /******************************************************
     * INFO REGARDING THE CURRENT SALE PHASE
     ******************************************************/
    function tokenPrice() public view returns (uint256) {
        return _tokenPrice;
    }

    function phaseSupplyLeft() public view returns (uint256) {
        return _phaseSupplyLeft;
    }

    function phaseSupplyTotal() public view returns (uint256) {
        return _phaseSupplyTotal;
    }  

    function phaseStartTimestamp() public view returns (uint256) {
        return _phaseStartTimestamp;
    }

    function phaseEndTimestamp() public view returns (uint256) {
        return _phaseEndTimestamp;
    } 

    function phaseIsActive() public view returns (bool){
        return (block.timestamp > _phaseStartTimestamp &&
                block.timestamp < _phaseEndTimestamp);
    }

    function currentPhase() public view returns (uint256){
        return _phase;
    }

    function weiRaised(uint256 phase) public view returns (uint256){
        return _weiRaised[phase];
    }

    function presaleWallet() public view returns (address){
        return _wallet;
    }



    /**
     * Purchase token. Provided amount is the total amount of token (without digits).
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     */
    function purchaseToken(uint256 amount) public payable nonReentrant {
        require(_msgSender() != address(0), "WeentarPresale: AddressZero cannot purchase.");
        require(phaseIsActive(), "WeentarPresale: Current phase is not active.");
        require(tokenPrice() != 0, "WeentarPresale: Token Price is not set");
        require(amount * 1 ether <= _phaseSupplyLeft, "WeentarPresale: Amount exceeds remaining supply of the current phase.");
        
        uint256 totalPrice = amount * _tokenPrice;
        require(msg.value >= totalPrice, "WeentarPresale: Payment too low.");

        _token.transfer(msg.sender, (amount * 1 ether));
        _weiRaised[_phase] = _weiRaised[_phase] + totalPrice;
        _phaseSupplyLeft = _phaseSupplyLeft - (amount * 1 ether);

        address payable client = payable(msg.sender);
        client.transfer(msg.value - totalPrice);
    }


    /**********************************************************
     * OWNER SECTION
     **********************************************************/

    function setTokenPrice(uint256 price) public onlyOwner {
        _tokenPrice = price;
    }

    function withdrawToken(uint256 amount) public onlyOwner {
        _token.transfer(owner(), amount);
    }

    function withdrawFunding() public {
        address payable walletPayable = payable(_wallet);
        walletPayable.transfer(address(this).balance);
    }

    function setCurrentPhase(uint256 supply, uint256 timestampStart, uint256 timestampEnd) public onlyOwner {
        require(supply <= _token.balanceOf(address(this)), "WeentarPresale: Supply value exceeds the token balance");
        require(timestampStart >= block.timestamp, "WeentarPresale: opening time is before current time");
        require(timestampEnd > timestampStart, "WeentarPresale: opening time is not before closing time");
        _phaseSupplyTotal = supply;
        _phaseSupplyLeft = supply;
        _phaseStartTimestamp = timestampStart;
        _phaseEndTimestamp = timestampEnd;
        _phase += 1;
    }

 
}