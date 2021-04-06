pragma solidity 0.8.1;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/Context.sol";

import "./IBEP20.sol";
import "./ReentrancyGuard.sol";


contract WeentarPresale is Context, Ownable, ReentrancyGuard {

    IBEP20 private _token;

    // phase detail
    uint256 private _tokenPrice;
    uint256 private _phaseSupplyLeft;
    uint256 private _phaseSupplyTotal;
    uint256 private _phaseStartTimestamp; //epoch in seconds
    uint256 private _phaseEndTimestamp; //epoch in seconds

    constructor(address token) {
        _token = IBEP20(token);
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
        return _phaseEndTimestamp;
    }

    function phaseEndTimestamp() public view returns (uint256) {
        return _phaseEndTimestamp;
    } 

    function phaseIsActive() public view returns (bool){
        return (block.timestamp > _phaseStartTimestamp &&
                block.timestamp < _phaseEndTimestamp);
    }

    /**
     * Purchase token. Provided amount is the total amount of token (without digits).
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     */
    function purchaseToken(uint256 amount) public payable nonReentrant {
        require(_msgSender() != address(0), "Sale: AddressZero cannot purchase.");
        require(phaseIsActive(), "Sale: Current phase is not active.");
        require(amount <= _phaseSupplyLeft, "Sale: Amount exceeds remaining supply of the current phase.");
        
        uint256 totalPrice = amount * _tokenPrice;
        require(msg.value >= totalPrice, "Sale: Payment too low.");

        _token.transfer(msg.sender, (amount * 1 ether));
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

    function withdrawFunding() public onlyOwner {
        address payable ownerPayable = payable(owner());
        ownerPayable.transfer(address(this).balance);
    }

    function setCurrentPhase(uint256 supply, uint256 timestampStart, uint256 timestampEnd) public onlyOwner {
        require(supply <= _token.balanceOf(address(this)));
        _phaseSupplyTotal = supply;
        _phaseSupplyLeft = supply;
        _phaseStartTimestamp = timestampStart;
        _phaseEndTimestamp = timestampEnd;
    }

 
}