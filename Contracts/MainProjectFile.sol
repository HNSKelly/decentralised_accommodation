
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

    function createAccommodation(string memory _location, uint256 _price) public {
        accommodations[accomCount] = Accommodation(_location, _price, true);
        accomCount++;
    }

    function updateAccommodationDetails(uint256 _id, string memory _location, uint256 _price, bool _available) public {
        require(_id < accomCount, "Accommodation ID does not exist.");
        accommodations[_id].location = _location;
        accommodations[_id].price = _price;
        accommodations[_id].available = _available;
    }

    function removeListing(uint256 _id) public {
        require(_id < accomCount, "Non valid accomodation ID");
        if (_id < accomCount - 1) {
            accommodations[_id] = accommodations[accomCount - 1]; // this Moves the last item to the deleted spot
        }
        delete accommodations[accomCount - 1]; // Remove the last item
        
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
    mapping(address => bool) public providersVerified;
    mapping(address => uint256) public refundsPending;

    event registeredProvider(address provider);
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
        providersVerified[_provider] = true;
        emit registeredProvider(_provider);
    }

    function checkProviderVerification(address _provider) public view returns (bool){
        return providersVerified[_provider];
    }

}
