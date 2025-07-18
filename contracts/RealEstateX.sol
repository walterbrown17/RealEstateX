// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract RealEstateX is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    Counters.Counter private _tokenIdCounter;

    struct Property {
        string physicalAddress;
        uint256 squareFootage;
        uint256 valuation;
        string coordinates;
        string description;
    }

    mapping(uint256 => Property) private _properties;
    mapping(uint256 => uint256) private _totalShares;
    mapping(uint256 => EnumerableSet.AddressSet) private _propertyOwners;
    mapping(uint256 => mapping(address => uint256)) private _shares;

    event PropertyMinted(uint256 indexed propertyId, address indexed owner);
    event SharesTransferred(uint256 indexed propertyId, address indexed from, address indexed to, uint256 shares);
    event ValuationUpdated(uint256 indexed propertyId, uint256 newValuation);

    constructor() ERC721("RealEstateX", "REX") Ownable(msg.sender) {}

    // ========================
    //      Core Functions
    // ========================

    function mintProperty(
        string calldata physicalAddress,
        uint256 squareFootage,
        uint256 valuation,
        string calldata coordinates,
        string calldata description,
        uint256 totalUnits
    ) external {
        uint256 propertyId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(msg.sender, propertyId);
        _registerProperty(propertyId, physicalAddress, squareFootage, valuation, coordinates, description, totalUnits);

        emit PropertyMinted(propertyId, msg.sender);
    }

    function _registerProperty(
        uint256 propertyId,
        string memory physicalAddress,
        uint256 squareFootage,
        uint256 valuation,
        string memory coordinates,
        string memory description,
        uint256 totalUnits
    ) internal {
        _properties[propertyId] = Property(physicalAddress, squareFootage, valuation, coordinates, description);
        _totalShares[propertyId] = totalUnits;
        _propertyOwners[propertyId].add(msg.sender);
        _shares[propertyId][msg.sender] = totalUnits;
    }

    function transferShares(
        uint256 propertyId,
        address to,
        uint256 shareUnits
    ) external {
        require(ownerOf(propertyId) == msg.sender, "Only property owner");
        require(_shares[propertyId][msg.sender] >= shareUnits, "Not enough shares");

        _shares[propertyId][msg.sender] -= shareUnits;
        _shares[propertyId][to] += shareUnits;
        _propertyOwners[propertyId].add(to);

        if (balanceOf(to) == 0) {
            _transfer(msg.sender, to, propertyId);
        }

        emit SharesTransferred(propertyId, msg.sender, to, shareUnits);
    }

    function updateValuation(uint256 propertyId, uint256 newValuation) external onlyOwner {
        _properties[propertyId].valuation = newValuation;
        emit ValuationUpdated(propertyId, newValuation);
    }

    // ========================
    //      View Functions
    // ========================

    function getPropertyInfo(uint256 propertyId) external view returns (Property memory) {
        return _properties[propertyId];
    }

    function getOwners(uint256 propertyId) external view returns (address[] memory) {
        return _propertyOwners[propertyId].values();
    }

    function getShares(uint256 propertyId, address holder) external view returns (uint256) {
        return _shares[propertyId][holder];
    }

    // ========================
    //      Overrides
    // ========================

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
