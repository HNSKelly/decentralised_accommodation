
pragma solidity ^0.8.0;

//provicer contract
contract AccommodationProvider {
    struct Accommodation {
        string location;
        uint256 price;
        bool available;
    }

    mapping(uint256 => Accommodation) public accommodations;
    uint256 public accomCount;
    address public regulatorAddress;
    address public providerOwner;

    event accommodationCreated(uint256 id, string location, uint256 price);
    event accommodationUpdated(uint256 id, string location, uint256 price, bool available);
    event accommodationRemoved(uint256 id);

    modifier onlyProviderOwner() {
        require(msg.sender == providerOwner, "Only the provider owner can execute this action");
        _;
    }

    
    modifier onlyRegisteredProvider() {
        SystemRegulator regulator = SystemRegulator(regulatorAddress);
        require(regulator.checkProviderVerification(providerOwner), "Provider is not registered with the regulator");
        _;
    }

    constructor(address _regulatorAddress) {
        regulatorAddress = _regulatorAddress;
        providerOwner = msg.sender;
    }


    function createAccommodation(string memory _location, uint256 _price) public onlyProviderOwner onlyRegisteredProvider {
        accommodations[accomCount] = Accommodation(_location, _price, true);
        emit accommodationCreated(accomCount, _location, _price);
        accomCount++;
    }

    function updateAccommodationDetails(uint256 _id, string memory _location, uint256 _price, bool _available) public onlyProviderOwner onlyRegisteredProvider {
        require(_id < accomCount, "Accommodation ID does not exist.");
        accommodations[_id].location = _location;
        accommodations[_id].price = _price;
        accommodations[_id].available = _available;
        emit accommodationUpdated(_id, _location, _price, _available);
    }

    function removeListing(uint256 _id) public onlyProviderOwner onlyRegisteredProvider {
        require(_id < accomCount, "Non valid accomodation ID");
        if (_id < accomCount - 1) {
            accommodations[_id] = accommodations[accomCount - 1]; // this Moves the last item to the deleted spot
        }
        delete accommodations[accomCount - 1]; // Remove the last item
        emit accommodationRemoved(_id);
        accomCount--; // Decrements the ammount
    }

    function getAccommodationDetails(uint256 _id) public view returns (string memory, uint256, bool) {
        require(_id < accomCount, "Accommodation ID does not exist.");
        Accommodation memory accommodation = accommodations[_id];
        return (accommodation.location, accommodation.price, accommodation.available);
    }
}

 
// AccommodationSeeker Contract
contract AccommodationSeeker {
    struct Booking {
        uint256 accommodationId;
        uint256 price;
        bool confirmed;
    }

    mapping(address => Booking[]) public bookings;

    // Reference to AccommodationProvider contract
    address public providerAddress;

    constructor(address _providerAddress) {
        providerAddress = _providerAddress;
    }

    function getBookingDetails(address _customer) public view returns (Booking[] memory) {
        return bookings[_customer];
    }

    function bookAccommodation(uint256 _id) public payable {
        AccommodationProvider provider = AccommodationProvider(providerAddress);
        (string memory location, uint256 price, bool available) = provider.getAccommodationDetails(_id);

        require(available, "Accommodation is not available");
        require(msg.value >= price, "Insufficient payment");

        bookings[msg.sender].push(Booking(_id, price, true));
    }

    function cancelAccommodation(uint256 _index) public {
        AccommodationProvider provider = AccommodationProvider(providerAddress);
        Booking storage booking = bookings[msg.sender][_index];
        
        require(booking.confirmed, "Booking not confirmed or already cancelled");

        provider.updateAccommodationDetails(booking.accommodationId, "", booking.price, true);
        delete bookings[msg.sender][_index];
    }
}


// SystemRegulator Contract
contract SystemRegulator {
    address public owner;
    uint256 public providerCount;
    mapping(address => bool) public providersVerified;
    mapping(address => uint256) public refundsPending;

    event verifiedProvider(address provider);
    event removedProvider(address provider);
    event registeredBooking(address indexed customer, uint256 accommodationId, uint256 amount);
    event processedRefund(address indexed customer, uint256 amount);

    modifier Owner(){
        require(msg.sender == owner, "Only the owner can execute this action");
        _;
    }

    constructor(){
        owner = msg.sender;
    }
    // Logic to add and verify a new Accommodation Provider
    function addAccommodationProvider(address _provider) public Owner {
        // Implement verification and adding logic here
        require(!providersVerified[_provider], "Provider is already verified");
        providersVerified[_provider] = true;
        providerCount++;
        emit verifiedProvider(_provider);
    }

    function removeAccommodationProvider(address _provider) public Owner {
        require(providersVerified[_provider], "Provider is not verified");
        providersVerified[_provider] = false;
        providerCount--;
        emit removedProvider(_provider);
    }

    function checkProviderVerification(address _provider) public view returns (bool){
        return providersVerified[_provider];
    }

    function getVerifiedProviderCount() public view returns (uint256) {
        return providerCount;
    }

    function registerBooking(address _customer, uint256 _accommodationId, uint256 _amount) public {
        require(providersVerified[msg.sender], "Caller is not a verified provider");
        refundsPending[_customer] += _amount;
        emit registeredBooking(_customer, _accommodationId, _amount);
    }

    function handleRefund(address _customer, uint256 _accommodationId, uint256 _amount) public {
        require(providersVerified[msg.sender], "Caller is not a verified provider");

        require(refundsPending[_customer] >= _amount, "Insufficient funds for refund");

        payable(_customer).transfer(_amount);
        refundsPending[_customer] -= _amount;
        emit processedRefund(_customer, _amount);
    }

}
