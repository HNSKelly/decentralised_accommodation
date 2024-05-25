
pragma solidity ^0.8.0;

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
    address[] public validAddresses;

    event AccommodationCreated(uint256 id, string location, uint256 price);
    event AccommodationUpdated(uint256 id, string location, uint256 price, bool available);
    event AccommodationRemoved(uint256 id);

    modifier onlyProviderOwner() {
        require(msg.sender == providerOwner, "Only the provider owner can execute this action");
        _;
    }

    modifier onlyValidAddress() {
        bool isValid = false;
        for (uint256 i = 0; i < validAddresses.length; i++) {
            if (validAddresses[i] == msg.sender) {
                isValid = true;
                break;
            }
        }
        require(isValid, "Address is not valid for this contract");
        _;
    }

    constructor(address[] memory _validAddresses) {
        providerOwner = msg.sender;
        validAddresses = _validAddresses;
    }

    function createAccommodation(string memory _location, uint256 _price) public onlyValidAddress {
        accommodations[accomCount] = Accommodation(_location, _price, true);
        emit AccommodationCreated(accomCount, _location, _price);
        accomCount++;
    }

    function updateAccommodationDetails(uint256 _id, string memory _location, uint256 _price, bool _available) public onlyValidAddress {
        require(_id < accomCount, "Accommodation ID does not exist.");
        accommodations[_id].location = _location;
        accommodations[_id].price = _price;
        accommodations[_id].available = _available;
        emit AccommodationUpdated(_id, _location, _price, _available);
    }

    function removeListing(uint256 _id) public onlyValidAddress {
        require(_id < accomCount, "Non valid accommodation ID");
        if (_id < accomCount - 1) {
            accommodations[_id] = accommodations[accomCount - 1];
        }
        delete accommodations[accomCount - 1];
        emit AccommodationRemoved(_id);
        accomCount--;
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





contract SystemRegulator {
    address public owner;
    address[] public newAddresses;

    event AllowedAddressAdded(address allowedAddress);
    event AllowedAddressRemoved(address allowedAddress);
    event AccommodationProviderDeployed(address newContractAddress);

    modifier Owner() {
        require(msg.sender == owner, "Only the owner can execute this action");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addNewAddress(address _newAddress) public Owner {
        newAddresses.push(_newAddress);
        emit AllowedAddressAdded(_newAddress);
    }

    function removeNewAddress(uint256 index) public Owner {
        require(index < newAddresses.length, "Index out of bounds");
        emit AllowedAddressRemoved(newAddresses[index]);
        newAddresses[index] = newAddresses[newAddresses.length - 1];
        newAddresses.pop();
    }

    function deployAccommodationProvider() external Owner returns (address) {
        AccommodationProvider newProvider = new AccommodationProvider(newAddresses);
        emit AccommodationProviderDeployed(address(newProvider));
        return address(newProvider);
    }
}

