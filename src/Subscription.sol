pragma solidity ^0.6.1;

import "../deps/SafeMath.sol";

contract Subscription {

    using SafeMath for uint256;

    address public owner;

    struct Subscriber {
        bool active;
        uint expiration;
    }

    struct Creator {
        string name;
        uint subCount;
        bool active;
        uint monthlyRate;
        mapping(address => Subscriber) subscribers;
    }

    mapping(address => Creator) internal creators;

    event Subscribed(address subscriberAddress, address creatorAddress);

    modifier ownerOnly {
        require(msg.sender == owner, "Only the owner is allowed to do that");
        _;
    }

    modifier creatorOnly {
        require(creators[msg.sender].active == true, "Only a creator is allowed to do that");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function subscribe1Month(address payable _creator) public payable {

        require(_creator != msg.sender,
        "You cannot subscribe to yourself.");
        require(creators[_creator].active == true,
        "Address is not an active creator.");
        require(msg.value.div(1 finney) >= creators[_creator].monthlyRate,
        "Not enough ether sent to cover the requested months of subscription");

        // state changes
        if(checkSubStatus(_creator, msg.sender)){
            creators[_creator].subscribers[msg.sender].expiration += 30 days;
        }
        else {
            creators[_creator].subCount += 1;
            creators[_creator].subscribers[msg.sender].active = true;
            creators[_creator].subscribers[msg.sender].expiration = now + 30 days;
        }

        // transfer ether to creator
        uint oneFin = 1 finney;
        _creator.transfer(creators[_creator].monthlyRate * oneFin);

        // call Subscribed event
        emit Subscribed(msg.sender, _creator);
    }

    // Enable and initialize the calling address as a creator
    function addCreator(string memory _name, uint finneyRate) public {
        require(creators[msg.sender].active != true, "Already a creator");
        uint oneFin = 1 finney;
        creators[msg.sender].monthlyRate = finneyRate * oneFin;
        creators[msg.sender].name = _name;
        creators[msg.sender].active = true;
        creators[msg.sender].subCount = 0;
    }

    // function to check subscription status
    function checkSubStatus(address _creator, address _subscriber) internal returns(bool status) {
        if(creators[_creator].subscribers[_subscriber].active == false) {
            return false;
        }
        if(now >= creators[_creator].subscribers[_subscriber].expiration) {
            creators[_creator].subscribers[_subscriber].active = false;
            creators[_creator].subCount -= 1;
            return false;
        }
        else {
            return true;
        }
    }

    // function to change monthly rate
    function changeRate(uint newRate) public creatorOnly {
        uint oneFin = 1 finney;
        creators[msg.sender].monthlyRate = newRate * oneFin;
    }

    // TODO: function to deactivate creator
    function deactivateCreator() public creatorOnly {

    }

    // function to get monthly Rate of creator
    function getMonthlyRate(address _creator) public view returns(uint amount) {
        return creators[_creator].monthlyRate;
    }
}