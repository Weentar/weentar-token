pragma solidity 0.8.1;

import "./BEP20.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";

contract WeentarToken is BEP20 {

    uint256 private _totalTokens;
    address private _admin;
    uint256 private _day;
    uint256 private _startTimestamp;
    bool private _startMinting;



    modifier onlyAdmin() {
        require(getAdmin() == _msgSender(), "WeentarToken: Caller is not the admin");
        _;
    }

    function setAdmin(address admin) public onlyOwner returns (bool){
        _admin = admin;
        return true;
    }
    function getAdmin() public view returns (address){
        return _admin;
    }

    constructor( uint256 totalTokens) BEP20("Weentar Token", "WTR", 18) {
        _mint(owner(), (totalTokens.mul(3)).div(10));
        _totalTokens = totalTokens;
    }

    function mint() public onlyAdmin returns (uint256){
        require(_startMinting, "WeentarToken: Tokens minting has not started yet");
        uint256 amountToMint;
        uint256 currentDay = getDay();
        if(_day < currentDay){
            if (_day < 90) {
                amountToMint = _totalTokens.mul(10).div(10000);
            }
            else if (_day < 365){
                amountToMint = _totalTokens.mul(5).div(10000);
            }
            else if (_day < 730){
                amountToMint = _totalTokens.mul(4).div(10000);
            }
            else if (_day < 1095){
                amountToMint = _totalTokens.mul(3).div(10000);
            }
            else if (_day < 1460){
                amountToMint = _totalTokens.mul(2).div(10000);
            }
            else if (_day < 2900){
                amountToMint = _totalTokens.mul(1).div(10000);
            }

            _mint(getAdmin(), amountToMint);
            _day = _day.add(1);
        }

        return amountToMint;

    }

    function setStartTimestamp() public onlyAdmin returns (bool){
        require(! _startMinting, "WeentarToken: Tokens already being minted");
        _startTimestamp = block.timestamp;
        _startMinting = true;
        return true;
    }

    function getDay() internal view returns (uint256){
        uint256 day = ((block.timestamp).sub(_startTimestamp)).div(86400);
        return day;

    }





    


    

}