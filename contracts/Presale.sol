
pragma solidity 0.8.1;

import "openzeppelin-solidity/contracts/utils/Address.sol";
import "openzeppelin-solidity/contracts/utils/Context.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "./IBEP20.sol";

abstract contract ReentrancyGuard {

    bool private _notEntered;

    constructor () {
        _notEntered = true;
    }

    modifier nonReentrant() {
        
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        _notEntered = true;
    }
}

contract WeentarPresale is Context, Ownable, ReentrancyGuard {

    // The token being sold
    IBEP20 private _token;

    // Address where funds are collected
    address payable private _wallet;

    // How many token units a buyer gets per wei.
    uint256 private _rate;

    // Amount of wei raised per phase
    mapping (uint256 => uint256) private _weiRaised;

    // Amount of tokens purchased by purchaser per phase
    mapping (address => mapping (uint256 => uint256)) private _tokensPurchased;

    // Total tokens purcahsed per phase
    mapping (uint256 => uint256) private _totalTokensPurchased;

    // Max limit for the presale
    uint256 private _cap;

    // Timestamp when the presale is started
    uint256 private _openingTime;

    // Timestamp when the presale is closed
    uint256 private _closingTime;

    // Phase of presale starts with value of 1 for first phase
    uint256 private _phase;

    // Phase for airdrop
    uint256 private _airdropPhase;

     // Amount for airdrop
    uint256 private _airdropAmount;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
     * Event for token airdropping
     * @param receiver who receives the airdrop
     * @param amount amount of tokens claimed
     */
    event TokensAirdropped(address indexed receiver,uint256 amount);

    /**
     * @param rate Number of token units a buyer gets per wei
     * @param wallet Address where collected funds will be forwarded to
     * @param token Address of the token being sold
     * @param cap Amount of max wei being raised
     * @param openingTime Time when the presale starts
     * @param openingTime Time when the presale closes
     */
    constructor (uint256 rate, address payable wallet, IBEP20 token, uint256 cap, uint256 openingTime, uint256 closingTime) public {
        require(rate > 0, "Presale: rate is 0");
        require(wallet != address(0), "Presale: wallet is the zero address");
        require(address(token) != address(0), "Presale: token is the zero address");
        require(cap > 0, "Presale: cap is 0");
        require(openingTime >= block.timestamp, "Presale: opening time is before current time");
        require(closingTime > openingTime, "Presale: opening time is not before closing time");
        _rate = rate;
        _wallet = wallet;
        _token = token;
        _cap = cap;
        _openingTime = openingTime;
        _closingTime = closingTime;
    }

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     * Note that other contracts will transfer funds with a base gas stipend
     * of 2300, which is not enough to call buyTokens. Consider calling
     * buyTokens directly when purchasing tokens from a contract.
     */
    fallback () external payable {
        buyTokens(_msgSender());
    }

    /**
     * @return the token being sold.
     */
    function token() public view returns (IBEP20) {
        return _token;
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address payable) {
        return _wallet;
    }

    /**
     * @return the number of token units a buyer gets per wei.
     */
    function rate() public view returns (uint256) {
        return _rate;
    }

    /**
     * @return the amount of wei raised.
     * @param phase Phase of presale
     */
    function weiRaised(uint256 phase) public view returns (uint256) {
        return _weiRaised[phase];
    }

     /**
     * @return the cap of the presale.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev Adjusts the cap during different phases of presale
     * @param cap Max limit for the presale
    */
    function adjustCap(uint256 cap) public onlyOwner {
        _cap = cap;
    }

    /**
     * @dev Adjusts the phase of presale
     * @param phase Phase of presale
    */
    function adjustPhase(uint256 phase) public onlyOwner {
        _phase = phase;
    }

    /**
     * @return the phase of the presale.
     */
    function phase() public view returns (uint256) {
        return _phase;
    }

     /**
     * @dev Adjusts the phase of airdrop
     * @param airdropPhase Phase of airdrop
    */
    function adjustAirdropPhase(uint256 airdropPhase) public onlyOwner {
        _airdropPhase = airdropPhase;
    }

    /**
     * @return the phase of the airdrop.
     */
    function airdropPhase() public view returns (uint256) {
        return _airdropPhase;
    }

    function adjustAirdropAmount(uint256 airdropAmount) public onlyOwner {
        _airdropAmount = airdropAmount;
    }

    /**
     * @return the amount for the airdrop.
     */
    function airdropAmount() public view returns (uint256) {
        return _airdropAmount;
    }
    
    /**
     * @dev Checks whether the cap has been reached.
     * @return Whether the cap was reached
     */
    function capReached() public view returns (bool) {
        return weiRaised(_phase) >= _cap;
    }

     /**
     * @dev Adjusts the rate during different phases of presale
     * @param rate token units a buyer gets per wei.
    */
     function adjustRate(uint256 rate) public onlyOwner {
       _rate = rate;
  
    }

    /**
     * @dev Reverts if not in presale time range.
     */
    modifier onlyWhileOpen {
        require(isOpen(), "TimedPresale: not open");
        _;
    }


    /**
     * @dev Transfers the remaining token back to the wallet
     * which is configured during the deploy of the contract
    */

    function returnUnsoldTokens() public onlyOwner {
      require(hasClosed(), "returnUnsoldTokens: Presale not closed!");
    
      IBEP20 token = IBEP20(token());
      token.transfer(wallet(), token.balanceOf(address(this)));
    }

    /**
     * @return the presale opening time.
     */
    function openingTime() public view returns (uint256) {
        return _openingTime;
    }

    /**
     * @return the presale closing time.
     */
    function closingTime() public view returns (uint256) {
        return _closingTime;
    }

    function adjustPresaleTime(uint256 openingTime, uint256 closingTime) public onlyOwner {

        require(openingTime >= block.timestamp, "Presale: opening time is before current time");
        require(closingTime > openingTime, "Presale: opening time is not before closing time");
        _openingTime = openingTime;
        _closingTime = closingTime;
    }


    /**
     * @return true if the presale is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
    }

    /**
     * @dev Checks whether the period in which the presale is open has already elapsed.
     * @return Whether presale period has elapsed
     */
    function hasClosed() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp > _closingTime;

    }
    

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     */
    function buyTokens(address beneficiary) public nonReentrant payable {
        require(_phase > 0, "Presale: Presale has not started");
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokenAmount = _getTokenAmount(weiAmount);

        // update state
        _weiRaised[_phase] = _weiRaised[_phase] + weiAmount;
        _tokensPurchased[_msgSender()][_phase] = _tokensPurchased[_msgSender()][_phase] + tokenAmount;
         _totalTokensPurchased[_phase] = _totalTokensPurchased[_phase] + tokenAmount;

        _token.transfer(beneficiary, tokenAmount);
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokenAmount);

        _wallet.transfer(msg.value);
  
    }



    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal onlyWhileOpen view {
        require(beneficiary != address(0), "Presale: beneficiary is the zero address");
        require(weiAmount != 0, "Presale: weiAmount is 0");
        require(weiRaised(_phase) + weiAmount <= _cap, "Presale: cap exceeded");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
     * @dev The rate in which BNB is converted to tokens.
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount * _rate;
    }
  
    function claimAirdrop() public nonReentrant {
        require(_airdropPhase > 0, "Presale: Airdrop has not started");
        uint256 claimableAmount = (_tokensPurchased[_msgSender()][_airdropPhase] / _totalTokensPurchased[_airdropPhase]) * _airdropAmount;
        _tokensPurchased[_msgSender()][_airdropPhase] = 0;

        require(claimableAmount > 0, "Presale: No airdrop to claim");

        _token.transfer(_msgSender(), claimableAmount);
        emit TokensAirdropped(_msgSender(), claimableAmount);

    }



}
