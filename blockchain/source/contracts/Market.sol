pragma solidity ^0.4.21;


import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./SNM.sol";
import "./Blacklist.sol";
import "./OracleUSD.sol";
import "./ProfileRegistry.sol";

contract Market is Ownable {

    using SafeMath for uint256;

    // DECLARATIONS

    enum DealStatus{
        STATUS_UNKNOWN,
        STATUS_ACCEPTED,
        STATUS_CLOSED
    }

    enum OrderType {
        ORDER_UNKNOWN,
        ORDER_BID,
        ORDER_ASK
    }

    enum OrderStatus {
        UNKNOWN,
        ORDER_INACTIVE,
        ORDER_ACTIVE
    }

    enum IdentityLevel {
        ANONIMOUS,
        REGISTRED,
        IDENTIFIED,
        PROFESSIONAL
    }

    enum RequestStatus {
        REQUEST_UNKNOWN,
        REQUEST_CREATED,
        REQUEST_CANCELED,
        REQUEST_REJECTED,
        REQUEST_ACCEPTED
    }

    struct Deal {
        uint64[] benchmarks;
        address supplierID;
        address consumerID;
        address masterID;
        uint askID;
        uint bidID;
        uint duration;
        uint price; //usd * 10^-18
        uint startTime;
        uint endTime;
        DealStatus status;
        uint blockedBalance;
        uint totalPayout;
        uint lastBillTS;
    }

    struct Order {
        OrderType orderType;
        OrderStatus orderStatus;
        address author;
        address counterparty;
        uint duration;
        uint256 price;
        bool[3] netflags;
        IdentityLevel identityLevel;
        address blacklist;
        bytes32 tag;
        uint64[] benchmarks;
        uint frozenSum;
        uint dealID;
    }

    struct ChangeRequest {
        uint dealID;
        OrderType requestType;
        uint price;
        uint duration;
        RequestStatus status;
    }

    // EVENTS

    event OrderPlaced(uint indexed orderID);
    event OrderUpdated(uint indexed orderID);

    event DealOpened(uint indexed dealID);
    event DealUpdated(uint indexed dealID);

    event Billed(uint indexed dealID, uint indexed paidAmount);

    event DealChangeRequestSet(uint indexed changeRequestID);
    event DealChangeRequestUpdated(uint indexed changeRequestID);

    event WorkerAnnounced(address indexed worker, address indexed master);
    event WorkerConfirmed(address indexed worker, address indexed master);
    event WorkerRemoved(address indexed worker, address indexed master);

    event NumBenchmarksUpdated(uint indexed newNum);

    // due postgres/sqlite couldn't work w uint64
    uint constant  maxBenchmarkValue  = 2 ** 63;

    // VARS

    SNM token;

    Blacklist bl;

    OracleUSD oracle;

    ProfileRegistry pr;

    uint ordersAmount = 0;

    uint dealAmount = 0;

    uint requestsAmount = 0;

    // current length of benchmarks array (12)
    uint benchmarksQuantity;

    mapping(uint => Order) public orders;

    mapping(uint => Deal) public deals;

    mapping(address => uint[]) dealsID;

    mapping(uint => ChangeRequest) requests;

    mapping(uint => uint[2]) actualRequests;

    mapping(address => address) masterOf;

    mapping(address => bool) isMaster;

    mapping(address => mapping(address => bool)) masterRequest;

   // INIT

    function Market(address _token, address _blacklist, address _oracle, address _profileRegistry, uint _benchmarksQuantity) public {
        token = SNM(_token);
        bl = Blacklist(_blacklist);
        oracle = OracleUSD(_oracle);
        pr = ProfileRegistry(_profileRegistry);
        benchmarksQuantity = _benchmarksQuantity;
    }

    // EXTERNAL

    // Order functions

    function PlaceOrder(
        OrderType _orderType,
        address _id_counterparty,
        uint _duration,
        uint _price,
        bool[3] _netflags,
        IdentityLevel _identityLevel,
        address _blacklist,
        bytes32 _tag,
        uint64[] _benchmarks
    ) public returns (uint){

        require(_benchmarks.length == benchmarksQuantity);

        for(uint i = 0; i < benchmarksQuantity; i++){
            require(_benchmarks[i] < maxBenchmarkValue);
        }

        uint lockedSum;

        if (_orderType == OrderType.ORDER_BID) {
            if (_duration == 0) {
                lockedSum = CalculatePayment(_price, 1 hours);
            } else if (_duration < 1 days) {
                lockedSum = CalculatePayment(_price, _duration);
            } else {
                lockedSum = CalculatePayment(_price , 1 days);
            }
            // this line contains err.
            require(token.transferFrom(msg.sender, this, lockedSum));
        }

        ordersAmount += 1;
        uint256 orderId = ordersAmount;

        orders[orderId] = Order(
            _orderType,
            OrderStatus.ORDER_ACTIVE,
            msg.sender,
            _id_counterparty,
            _duration,
            _price,
            _netflags,
            _identityLevel,
            _blacklist,
            _tag,
            _benchmarks,
            lockedSum,
            0
        );

        OrderPlaced(orderId);
        return orderId;
    }

    function CancelOrder(uint orderID) public returns (bool){
        require(orderID <= ordersAmount);
        require(orders[orderID].orderStatus == OrderStatus.ORDER_ACTIVE);
        require(orders[orderID].author == msg.sender);


        require(token.transfer(msg.sender, orders[orderID].frozenSum));
        orders[orderID].orderStatus = OrderStatus.ORDER_INACTIVE;

        OrderUpdated(orderID);
        return true;
    }


    function QuickBuy(uint askID) public {
        var ask = orders[askID];
        require(ask.orderType == OrderType.ORDER_ASK);
        require(ask.orderStatus == OrderStatus.ORDER_ACTIVE);

        require(pr.CheckProfileLevel(msg.sender, uint(ask.identityLevel)));
        require(bl.Check(msg.sender, GetMaster(ask.author)) == false && bl.Check(ask.author, msg.sender) == false);
        require(bl.Check(ask.blacklist, msg.sender) == false);

        PlaceOrder(
            OrderType.ORDER_BID,
            ask.author,
            ask.duration,
            ask.price,
            ask.netflags,
            IdentityLevel.ANONIMOUS,
            address(0),
            bytes32(0),
            ask.benchmarks);

        OpenDeal(askID, GetOrdersAmount());

    }

    // Deal functions

    function OpenDeal(uint _askID, uint _bidID) public {
        Order ask = orders[_askID];
        Order bid = orders[_bidID];

        require(ask.orderStatus == OrderStatus.ORDER_ACTIVE && bid.orderStatus == OrderStatus.ORDER_ACTIVE);
        require((ask.counterparty == 0x0 || ask.counterparty == GetMaster(bid.author)) && (bid.counterparty == 0x0 || bid.counterparty == GetMaster(ask.author)));
        require(ask.orderType == OrderType.ORDER_ASK);
        require(bid.orderType == OrderType.ORDER_BID);
        require(bl.Check(bid.blacklist, GetMaster(ask.author)) == false && bl.Check(ask.blacklist, bid.author) == false);
        require(bl.Check(bid.author, GetMaster(ask.author)) == false && bl.Check(ask.author, bid.author) == false);
        require(ask.price <= bid.price);
        require(ask.duration >= bid.duration);
        // profile level check
        require(pr.CheckProfileLevel(bid.author, uint(ask.identityLevel)));
        require(pr.CheckProfileLevel(ask.author, uint(bid.identityLevel)));

        for (uint i = 0; i < 3; i++) {
            // implementation: when bid contains requirement, ask necessary needs to have this
            // if ask have this one - pass
            require(!bid.netflags[i] || ask.netflags[i]);
        }

        for (i = 0; i < ask.benchmarks.length; i++) {
            require(ask.benchmarks[i] >= bid.benchmarks[i]);
        }

        dealAmount = dealAmount + 1;
        address master = GetMaster(ask.author);
        orders[_askID].orderStatus = OrderStatus.ORDER_INACTIVE;
        orders[_bidID].orderStatus = OrderStatus.ORDER_INACTIVE;
        orders[_askID].dealID = dealAmount;
        orders[_bidID].dealID = dealAmount;

        OrderUpdated(_askID);
        OrderUpdated(_bidID);

        uint startTime = block.timestamp;
        uint endTime = 0;
        // `0` - for spot deal

        // if deal is normal
        if (ask.duration != 0) {
            endTime = startTime + bid.duration;
        }

        uint blockedBalance = bid.frozenSum;
        deals[dealAmount] = Deal(ask.benchmarks, ask.author, bid.author, master, _askID, _bidID, bid.duration, ask.price, startTime, endTime, DealStatus.STATUS_ACCEPTED, blockedBalance, 0, block.timestamp);
        DealOpened(dealAmount);
    }

    function CloseDeal(uint dealID, bool blacklisted) public returns (bool){
        require((deals[dealID].status == DealStatus.STATUS_ACCEPTED));
        require(msg.sender == deals[dealID].supplierID || msg.sender == deals[dealID].consumerID || msg.sender == deals[dealID].masterID);

        if (block.timestamp <= deals[dealID].startTime + deals[dealID].duration) {
            // after endTime
            require(deals[dealID].consumerID == msg.sender);
        }

        AddToBlacklist(dealID, blacklisted);
        Bill(dealID);
        InternalCloseDeal(dealID);

        if (deals[dealID].blockedBalance > 0) {
            require(token.transfer(deals[dealID].consumerID, deals[dealID].blockedBalance));
        }
        return true;
    }

    function Bill(uint dealID) public returns (bool){
        require(deals[dealID].status == DealStatus.STATUS_ACCEPTED);
        require(msg.sender == deals[dealID].supplierID || msg.sender == deals[dealID].consumerID || msg.sender == deals[dealID].masterID);
        var deal = deals[dealID];

        uint paidAmount;

        if (!IsSpot(dealID) && deal.lastBillTS >= deal.endTime) {
            //means we already billed deal after endTime
            return true;
        } else if (!IsSpot(dealID) && block.timestamp > deal.endTime && deal.lastBillTS < deal.endTime) {
            paidAmount = CalculatePayment(deal.price, deal.endTime - deal.lastBillTS);
        } else {
            paidAmount = CalculatePayment(deal.price, block.timestamp - deal.lastBillTS);
        }

        if (paidAmount > deal.blockedBalance) {
            if (token.balanceOf(deal.consumerID) >= paidAmount - deal.blockedBalance) {
                require(token.transferFrom(deal.consumerID, this, paidAmount - deal.blockedBalance));
                deals[dealID].blockedBalance = deals[dealID].blockedBalance.add(paidAmount - deal.blockedBalance);
            } else {
                Billed(dealID, deals[dealID].blockedBalance);
                InternalCloseDeal(dealID);
                require(token.transfer(deal.masterID, deal.blockedBalance));
                deals[dealID].lastBillTS = block.timestamp;
                deals[dealID].totalPayout = deals[dealID].totalPayout.add(deal.blockedBalance);
                deals[dealID].blockedBalance = 0;
                return true;
            }
        }
        require(token.transfer(deal.masterID, paidAmount));
        deals[dealID].blockedBalance = deals[dealID].blockedBalance.sub(paidAmount);
        deals[dealID].totalPayout = deals[dealID].totalPayout.add(paidAmount);
        deals[dealID].lastBillTS = block.timestamp;
        Billed(dealID, paidAmount);

        uint nextPeriod;

        if (IsSpot(dealID)){
            if (deal.status == DealStatus.STATUS_CLOSED) {
                return true;
            } else {
                nextPeriod = 1 hours;
            }
        } else {
            if (block.timestamp > deal.endTime) {
                return true; //we don't reserve funds for next period
            } else if (deal.endTime - block.timestamp < 1 days) {
                nextPeriod = deal.endTime - block.timestamp;
            } else
                nextPeriod = 1 days;
        }


        if (CalculatePayment(deal.price, nextPeriod) > deals[dealID].blockedBalance){
            uint nextPeriodSum = CalculatePayment(deal.price, nextPeriod).sub(deals[dealID].blockedBalance);

            if (token.balanceOf(deal.consumerID) >= nextPeriodSum) {
                require(token.transferFrom(deal.consumerID, this, nextPeriodSum));
                deals[dealID].blockedBalance = deals[dealID].blockedBalance.add(nextPeriodSum);
            } else {
                Billed(dealID, deal.blockedBalance);
                InternalCloseDeal(dealID);
                require(token.transfer(deal.masterID, deal.blockedBalance));
                deals[dealID].blockedBalance = 0;
                return true;
            }
        }
        return true;
    }

    function CreateChangeRequest(uint dealID, uint newPrice, uint newDuration) public returns (uint changeRequestID) {
        require(msg.sender == deals[dealID].consumerID || msg.sender == deals[dealID].masterID || msg.sender == deals[dealID].supplierID);
        require(deals[dealID].status == DealStatus.STATUS_ACCEPTED);

        if (IsSpot(dealID)) {
            require(newDuration == 0);
        }

        requestsAmount += 1;

        OrderType requestType;

        if (msg.sender == deals[dealID].consumerID) {
            requestType = OrderType.ORDER_BID;
        } else {
            requestType = OrderType.ORDER_ASK;
        }

        requests[requestsAmount] = ChangeRequest(dealID, requestType, newPrice, newDuration, RequestStatus.REQUEST_CREATED);
        DealChangeRequestSet(requestsAmount);

        if (requestType == OrderType.ORDER_BID) {
            DealChangeRequestUpdated(actualRequests[dealID][1]);
            requests[actualRequests[dealID][1]].status = RequestStatus.REQUEST_CANCELED;
            actualRequests[dealID][1] = requestsAmount;
            var matchingRequest = requests[actualRequests[dealID][0]];

            if (newDuration == deals[dealID].duration && newPrice > deals[dealID].price) {
                requests[requestsAmount].status = RequestStatus.REQUEST_ACCEPTED;
                Bill(dealID);
                deals[dealID].price = newPrice;
                actualRequests[dealID][1] = 0;
                DealChangeRequestUpdated(requestsAmount);
            } else if (matchingRequest.status == RequestStatus.REQUEST_CREATED && matchingRequest.duration >= newDuration && matchingRequest.price <= newPrice) {
                requests[requestsAmount].status = RequestStatus.REQUEST_ACCEPTED;
                requests[actualRequests[dealID][0]].status = RequestStatus.REQUEST_ACCEPTED;
                actualRequests[dealID][0] = 0;
                actualRequests[dealID][1] = 0;
                Bill(dealID);
                deals[dealID].price = matchingRequest.price;
                deals[dealID].duration = newDuration;
                DealChangeRequestUpdated(requestsAmount);
                DealChangeRequestUpdated(actualRequests[dealID][0]);
            } else {
                return requestsAmount;
            }

            requests[actualRequests[dealID][1]].status = RequestStatus.REQUEST_CANCELED;
            DealChangeRequestUpdated(actualRequests[dealID][1]);
            actualRequests[dealID][1] = requestsAmount;
        }

        if (requestType == OrderType.ORDER_ASK) {
            DealChangeRequestUpdated(actualRequests[dealID][0]);
            requests[actualRequests[dealID][0]].status = RequestStatus.REQUEST_CANCELED;
            actualRequests[dealID][0] = requestsAmount;
            matchingRequest = requests[actualRequests[dealID][1]];

            if (newDuration == deals[dealID].duration && newPrice < deals[dealID].price) {
                requests[requestsAmount].status = RequestStatus.REQUEST_ACCEPTED;
                Bill(dealID);
                deals[dealID].price = newPrice;
                actualRequests[dealID][0] = 0;
                DealChangeRequestUpdated(requestsAmount);
            } else if (matchingRequest.status == RequestStatus.REQUEST_CREATED && matchingRequest.duration <= newDuration && matchingRequest.price >= newPrice) {
                requests[requestsAmount].status = RequestStatus.REQUEST_ACCEPTED;
                actualRequests[dealID][0] = 0;
                actualRequests[dealID][1] = 0;
                Bill(dealID);
                deals[dealID].price = newPrice;
                deals[dealID].duration = matchingRequest.duration;
                DealChangeRequestUpdated(requestsAmount);
                DealChangeRequestUpdated(actualRequests[dealID][1]);
            } else  {
                return requestsAmount;
            }

        }

        deals[dealID].endTime = deals[dealID].startTime + deals[dealID].duration;
        return requestsAmount;
    }


    function CancelChangeRequest(uint changeRequestID) public returns (bool) {
        var request = requests[changeRequestID];
        require(msg.sender == deals[request.dealID].supplierID || msg.sender == deals[request.dealID].masterID || msg.sender == deals[request.dealID].consumerID);
        require(request.status != RequestStatus.REQUEST_ACCEPTED);

        if (request.requestType == OrderType.ORDER_ASK) {
            if(msg.sender == deals[request.dealID].consumerID){
                requests[changeRequestID].status = RequestStatus.REQUEST_REJECTED;
            } else {
                requests[changeRequestID].status = RequestStatus.REQUEST_CANCELED;
            }
            actualRequests[request.dealID][0] = 0;
            DealChangeRequestUpdated(changeRequestID);
        }

        if (request.requestType == OrderType.ORDER_BID) {
            if(msg.sender == deals[request.dealID].consumerID){
                requests[changeRequestID].status = RequestStatus.REQUEST_CANCELED;
            } else {
                requests[changeRequestID].status = RequestStatus.REQUEST_REJECTED;
            }
            actualRequests[request.dealID][1] = 0;
            DealChangeRequestUpdated(changeRequestID);
        }


        return true;
    }


    // Master-worker functions

    function RegisterWorker(address _master) public returns (bool) {
        require(GetMaster(msg.sender) == msg.sender);
        require(isMaster[msg.sender] == false);
        require(GetMaster(_master) == _master);
        masterRequest[_master][msg.sender] = true;
        WorkerAnnounced(msg.sender, _master);
        return true;
    }

    function ConfirmWorker(address _worker) public returns (bool) {
        require(masterRequest[msg.sender][_worker] == true);
        masterOf[_worker] = msg.sender;
        isMaster[msg.sender] = true;
        delete masterRequest[msg.sender][_worker];
        WorkerConfirmed(_worker, msg.sender);
        return true;
    }

    function RemoveWorker(address _worker, address _master) public returns (bool) {
        require(GetMaster(_worker) == _master && (msg.sender == _worker || msg.sender == _master));
        delete masterOf[_worker];
        WorkerRemoved(_worker, _master);
        return true;
    }

    // GETTERS

    function GetOrderInfo(uint orderID) view public
    returns (
        OrderType orderType,
        address author,
        address counterparty,
        uint duration,
        uint price,
        bool[3] netflags,
        IdentityLevel identityLevel,
        address blacklist,
        bytes32 tag,
        uint64[] benchmarks,
        uint frozenSum
    ){
        Order memory order = orders[orderID];
        return (
        order.orderType,
        order.author,
        order.counterparty,
        order.duration,
        order.price,
        order.netflags,
        order.identityLevel,
        order.blacklist,
        order.tag,
        order.benchmarks,
        order.frozenSum
        );
    }


    function GetOrderParams(uint orderID) view public
    returns (
        OrderStatus orderStatus,
        uint dealID
    ){
        Order memory order = orders[orderID];
        return (
        order.orderStatus,
        order.dealID
        );
    }

    function GetDealInfo(uint dealID) view public
    returns (
        uint64[] benchmarks,
        address supplierID,
        address consumerID,
        address masterID,
        uint askID,
        uint bidID,
        uint startTime
    ){
        return (
        deals[dealID].benchmarks,
        deals[dealID].supplierID,
        deals[dealID].consumerID,
        deals[dealID].masterID,
        deals[dealID].askID,
        deals[dealID].bidID,
        deals[dealID].startTime

        );
    }

    function GetDealParams(uint dealID) view public
    returns (
        uint duration,
        uint price,
        uint endTime,
        DealStatus status,
        uint blockedBalance,
        uint totalPayout,
        uint lastBillTS
    ){
        //Deal memory deal = deals[dealID];
        return (
        deals[dealID].duration,
        deals[dealID].price,
        deals[dealID].endTime,
        deals[dealID].status,
        deals[dealID].blockedBalance,
        deals[dealID].totalPayout,
        deals[dealID].lastBillTS
        );
    }

    function GetMaster(address _worker) view public returns (address master) {
        if (masterOf[_worker] == 0x0 || masterOf[_worker] == _worker) {
            master = _worker;
        } else {
            master = masterOf[_worker];
        }
    }

    function GetChangeRequestInfo(uint changeRequestID) view public
    returns (
        uint dealID,
        OrderType requestType,
        uint price,
        uint duration,
        RequestStatus status
    ){
        return (
        requests[changeRequestID].dealID,
        requests[changeRequestID].requestType,
        requests[changeRequestID].price,
        requests[changeRequestID].duration,
        requests[changeRequestID].status
        );
    }

    function GetDealsAmount() public view returns (uint){
        return dealAmount;
    }

    function GetOrdersAmount() public view returns (uint){
        return ordersAmount;
    }

    function GetChangeRequestsAmount() public view returns (uint){
        return requestsAmount;
    }

    function GetBenchmarksQuantity() public view returns (uint) {
        return benchmarksQuantity;
    }
    // INTERNAL

    function IsSpot(uint dealID) internal view returns (bool){
        if (deals[dealID].duration == 0){
            return true;
        } else {
            return false;
        }
    }

    function CalculatePayment(uint _price, uint _period) internal view returns (uint) {
        var rate = oracle.getCurrentPrice();
        return rate.mul(_price).mul(_period).div(1e18);
    }

    function AddToBlacklist(uint dealID, bool blacklisted) internal {
        if (msg.sender == deals[dealID].consumerID && blacklisted == true) {
            bl.Add(deals[dealID].consumerID, deals[dealID].masterID);
        }
    }

    function InternalCloseDeal(uint dealID) internal {
        if (deals[dealID].status == DealStatus.STATUS_CLOSED){
            return;
        } else {
            require((deals[dealID].status == DealStatus.STATUS_ACCEPTED));
            require(msg.sender == deals[dealID].consumerID || msg.sender == deals[dealID].supplierID || msg.sender == deals[dealID].masterID);
            deals[dealID].status = DealStatus.STATUS_CLOSED;
            deals[dealID].endTime = block.timestamp;
            DealUpdated(dealID);
        }
    }

    function SetProfileRegistryAddress(address _newPR) onlyOwner public returns (bool) {
        pr = ProfileRegistry(_newPR);
        return true;
    }

    function SetBlacklistAddress(address _newBL) onlyOwner public returns (bool) {
        bl = Blacklist(_newBL);
        return true;
    }

    function SetOracleAddress (address _newOracle) onlyOwner public returns (bool) {
        require(OracleUSD(_newOracle).getCurrentPrice() != 0);
        oracle = OracleUSD(_newOracle);
        return true;
    }

    function SetBenchmarksQuantity(uint _newQuantity) onlyOwner public returns (bool) {
        require(_newQuantity > benchmarksQuantity);
        NumBenchmarksUpdated(_newQuantity);
        benchmarksQuantity = _newQuantity;
        return true;
    }
}