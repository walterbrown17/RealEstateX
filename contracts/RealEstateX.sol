// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract RealEstateX is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    Counters.Counter private tokenIdTracker;

    struct Property {
        string physicalAddress;
        uint256 squareFootage;
        uint256 valuation;
        string coordinates;
        string description;
    }

    // ========== Storage ==========

    mapping(uint256 => Property) private properties;
    mapping(uint256 => uint256) private totalShares;
    mapping(uint256 => EnumerableSet.AddressSet) private propertyOwners;
    mapping(uint256 => mapping(address => uint256)) private ownerShares;

    // ========== Events ==========

    event PropertyMinted(uint256 indexed propertyId, address indexed owner);
    event SharesTransferred(uint256 indexed propertyId, address indexed from, address indexed to, uint256 shares);
    event ValuationUpdated(uint256 indexed propertyId, uint256 newValuation);

    // ========== Constructor ==========

    constructor() ERC721("RealEstateX", "REX") Ownable(msg.sender) {}

    // ========== Core Functions ==========

    function mintProperty(
        string calldata _address,
        uint256 _squareFootage,
        uint256 _valuation,
        string calldata _coordinates,
        string calldata _description,
        uint256 _totalUnits
    ) external {
        uint256 newPropertyId = tokenIdTracker.current();
        tokenIdTracker.increment();

        _safeMint(msg.sender, newPropertyId);

        properties[newPropertyId] = Property(_address, _squareFootage, _valuation, _coordinates, _description);
        totalShares[newPropertyId] = _totalUnits;
        propertyOwners[newPropertyId].add(msg.sender);
        ownerShares[newPropertyId][msg.sender] = _totalUnits;

        emit PropertyMinted(newPropertyId, msg.sender);
    }

    function transferShares(
        uint256 _propertyId,
        address _to,
        uint256 _sharesToTransfer
    ) external {
        require(ownerOf(_propertyId) == msg.sender, "Caller is not the property NFT owner");
        require(ownerShares[_propertyId][msg.sender] >= _sharesToTransfer, "Insufficient shares");

        ownerShares[_propertyId][msg.sender] -= _sharesToTransfer;
        ownerShares[_propertyId][_to] += _sharesToTransfer;
        propertyOwners[_propertyId].add(_to);

        if (balanceOf(_to) == 0) {
            _transfer(msg.sender, _to, _propertyId);
        }

        emit SharesTransferred(_propertyId, msg.sender, _to, _sharesToTransfer);
    }

    function updateValuation(uint256 _propertyId, uint256 _newValuation) external onlyOwner {
        properties[_propertyId].valuation = _newValuation;
        emit ValuationUpdated(_propertyId, _newValuation);
    }

    // ========== View Functions ==========

    function getPropertyInfo(uint256 _propertyId) external view returns (Property memory) {
        return properties[_propertyId];
    }

    function getOwners(uint256 _propertyId) external view returns (address[] memory) {
        return propertyOwners[_propertyId].values();
    }

    function getShares(uint256 _propertyId, address _owner) external view returns (uint256) {
        return ownerShares[_propertyId][_owner];
    }

    // ========== Overrides ==========

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
