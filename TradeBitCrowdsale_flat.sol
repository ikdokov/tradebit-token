pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


interface Token {
    function transferFrom(address from, address to, uint256 amount) public returns (bool);
}

contract TradeBitCrowdsale {

    uint public tbtHardCap = 375000000 * (10 ** 18);
    
    // include SafeMath - give oportunity to use it directly on uint256 type
    using SafeMath for uint256;

    Token tokenContract;

    address owner = msg.sender;

    // start and end timestamps where investments are allowed (both inclusive)
    uint256 public startTime;
    uint256 public endTime;

    uint256 public tbtRaised;
    
    uint256 twentyDaysInSeconds = 1728000;
    
    // campain phases - used to modify rate 
    uint256 timePhase2;
    uint256 timePhase3;

    uint ratePhase1 = 7500;
    uint ratePhase2 = 6250;
    uint ratePhase3 = 5000;
    /**
    * event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    function TradeBitCrowdsale(uint256 _startTime, address _tokenContractAddress) public {
        tokenContract = Token(_tokenContractAddress);
        startTime = _startTime;
        timePhase2 = startTime + twentyDaysInSeconds;
        timePhase3 = timePhase2 + twentyDaysInSeconds;
        endTime = timePhase3 + twentyDaysInSeconds;
    }

    // fallback function can be used to buy tokens
    function () public payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address beneficiary) public payable {
        require(validPurchase());

        uint256 weiAmount = msg.value;

        uint256 tbTokens = weiAmount.mul(getRate());

        tokenContract.transferFrom(owner, beneficiary, tbTokens);

        tbtRaised = tbtRaised.add(tbTokens);

        owner.transfer(weiAmount);

        TokenPurchase(msg.sender, beneficiary, weiAmount, tbTokens);
    }

    // change convertion rate based on campaing phase
    function getRate() public view returns (uint256) {
        if (now < timePhase2) {
            return ratePhase1;
        } else if (now < timePhase3) {
            return ratePhase2;
        } else {
            return ratePhase3;
        }
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase && tbtRaised < tbtHardCap;
    }
    
    function hasStarted() public view returns (bool) {
        return now >= startTime;
    }

    function hasEnded() public view returns (bool) {
        return now > endTime;
    }
}