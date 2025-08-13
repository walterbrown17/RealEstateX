// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract RealEstateX is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    Counters.Counter private _propertyCounter;

    struct Property {
        string location;
        uint256 area;
        uint256 valuation;
        string coordinates;
        string description;
    }

    // ========== Storage ==========
    mapping(uint256 => Property) private _propertyDetails;
    mapping(uint256 => uint256) private _propertyShares;
    mapping(uint256 => EnumerableSet.AddressSet) private _shareholders;
    mapping(uint256 => mapping(address => uint256)) private _shares;

    // ========== Events ==========
    event PropertyMinted(uint256 indexed propertyId, address indexed creator);
    event SharesTransferred(uint256 indexed propertyId, address indexed from, address indexed to, uint256 amount);
    event ValuationUpdated(uint256 indexed propertyId, uint256 newValuation);

    // ========== Constructor ==========
    constructor() ERC721("RealEstateX", "REX") {}

    // ========== External Functions ==========
    function mintProperty(
        string calldata location,
        uint256 area,
        uint256 valuation,
        string calldata coordinates,
        string calldata description,
        uint256 shareUnits
    ) external {
        uint256 propertyId = _propertyCounter.current();
        _propertyCounter.increment();

        _safeMint(msg.sender, propertyId);

        _propertyDetails[propertyId] = Property({
            location: location,
            area: area,
            valuation: valuation,
            coordinates: coordinates,
            description: description
        });

        _propertyShares[propertyId] = shareUnits;
        _shareholders[propertyId].add(msg.sender);
        _shares[propertyId][msg.sender] = shareUnits;

        emit PropertyMinted(propertyId, msg.sender);
    }

    function transferShares(
        uint256 propertyId,
        address to,
        uint256 amount
    ) external {
        require(_exists(propertyId), "Property does not exist");
        require(ownerOf(propertyId) == msg.sender, "Caller is not the owner");
        require(_shares[propertyId][msg.sender] >= amount, "Insufficient shares");
        require(to != address(0), "Invalid recipient");

        _shares[propertyId][msg.sender] -= amount;
        _shares[propertyId][to] += amount;
        _shareholders[propertyId].add(to);

        // Transfer NFT if sender no longer holds any shares
        if (_shares[propertyId][msg.sender] == 0) {
            _transfer(msg.sender, to, propertyId);
        }

        emit SharesTransferred(propertyId, msg.sender, to, amount);
    }

    function updateValuation(uint256 propertyId, uint256 newValuation) external onlyOwner {
        require(_exists(propertyId), "Invalid property ID");
        _propertyDetails[propertyId].valuation = newValuation;
        emit ValuationUpdated(propertyId, newValuation);
    }

    // ========== View Functions ==========
    function getPropertyInfo(uint256 propertyId) external view returns (Property memory) {
        return _propertyDetails[propertyId];
    }

    function getShareholders(uint256 propertyId) external view returns (address[] memory) {
        return _shareholders[propertyId].values();
    }

    function getShareBalance(uint256 propertyId, address account) external view returns (uint256) {
        return _shares[propertyId][account];
    }

    function getTotalShares(uint256 propertyId) external view returns (uint256) {
        return _propertyShares[propertyId];
    }

    // ========== Overrides ==========
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
