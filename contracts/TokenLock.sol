pragma solidity 0.8.1;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/Context.sol";

import "./IBEP20.sol";


contract TokenLock is Context, Ownable {

    IBEP20 private _token;
    uint256 private _lockedTime;
    bool private _locked;
 
    // wallets, amount of tokens and token period info
    address private _teamWallet;
    uint256 private _teamTokenAmount;
    uint256 private _teamTimeLockedInDays;
    address private _investorWallet;
    uint256 private _investor1TokenAmount;
    uint256 private _investor1TimeLockedInDays;
    uint256 private _investor2TokenAmount;
    uint256 private _investor2TimeLockedInDays;

   
    constructor(address token, address teamWallet, uint256 teamTokenAmount, uint256 teamTimeLockedInDays, address investorWallet, uint256 investor1TokenAmount, uint256 investor1TimeLockedInDays, uint256 investor2TokenAmount, uint256 investor2TimeLockedInDays ) {
        _token = IBEP20(token);
        _teamWallet = teamWallet;
        _teamTokenAmount = teamTokenAmount;
        _teamTimeLockedInDays = teamTimeLockedInDays;
        _investorWallet = investorWallet;
        _investor1TokenAmount = investor1TokenAmount;
        _investor1TimeLockedInDays = investor1TimeLockedInDays;
        _investor2TokenAmount = investor2TokenAmount;
        _investor2TimeLockedInDays = investor2TimeLockedInDays;

    }

    function token() public view returns (IBEP20){
        return _token;
    }

    function tokensLocked() public view returns (uint256){
        return _token.balanceOf(address(this));
    }

    function teamWallet() public view returns (address){
        return _teamWallet;
    }
    function investorWallet() public view returns (address){
        return _investorWallet;
    }
    
    function teamTokenLocked() public view returns (uint256){
        return _locked ? _teamTokenAmount: 0;
    }
    function investorTokenLocked() public view returns (uint256){
        return _locked ? _investor1TokenAmount + _investor2TokenAmount: 0;
    }

    function timeRemainingForUnlockingTeamToken() public view returns (uint256){
        return (_lockedTime + _teamTimeLockedInDays*86400 > block.timestamp) ? _lockedTime + _teamTimeLockedInDays*86400 - block.timestamp: 0;
    }

    function timeRemainingForUnlockingInvestor1Token() public view returns (uint256){
        return (_lockedTime + _investor1TimeLockedInDays*86400 > block.timestamp) ? _lockedTime + _investor1TimeLockedInDays*86400 - block.timestamp: 0;
    }

    function timeRemainingForUnlockingInvestor2Token() public view returns (uint256){
        return (_lockedTime + _investor1TimeLockedInDays*86400 > block.timestamp) ? _lockedTime + _investor2TimeLockedInDays*86400 - block.timestamp: 0;
    }

    function startLock() public onlyOwner {
        require(!_locked,"TokenLock: Tokens already locked.");
        _lockedTime = block.timestamp;
        _token.transferFrom(_msgSender(), address(this), _teamTokenAmount + _investor1TokenAmount + _investor2TokenAmount );
        _locked = true;
     
    }
    
    function unlock() public {
        uint256 day = (block.timestamp - _lockedTime) / 86400;
        if(day >= _teamTimeLockedInDays){
            _token.transfer(_teamWallet, _teamTokenAmount);
            _teamTokenAmount = 0;
        }
        
        if(day >= _investor1TimeLockedInDays){
            _token.transfer(_investorWallet, _investor1TokenAmount);
            _investor1TokenAmount = 0;
        }
        
        if(day >= _investor2TimeLockedInDays){
            _token.transfer(_investorWallet, _investor2TokenAmount);
            _investor2TokenAmount = 0;
        }
    
    }

}


