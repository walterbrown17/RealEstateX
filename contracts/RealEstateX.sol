// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract RealEstateX is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    Counters.Counter private _propertyIdTracker;

    // ========= Structs =========
    struct Property {
        string location;
        uint256 area;
        uint256 valuation;
        string coordinates;
        string description;
    }

    // ========== State Variables ==========
    mapping(uint256 => Property) private _propertyDetails;
    mapping(uint256 => uint256) private _propertyShares;
    mapping(uint256 => EnumerableSet.AddressSet) private _propertyShareholders;
    mapping(uint256 => mapping(address => uint256)) private _shareBalances;

    // ========== Events ==========
    event PropertyCreated(uint256 indexed propertyId, address indexed creator);
    event SharesTransferred(uint256 indexed propertyId, address indexed from, address indexed to, uint256 shares);
    event PropertyValuationUpdated(uint256 indexed propertyId, uint256 newValuation);

    // ========== Constructors ==========
    constructor() ERC721("RealEstateX", "REX") {}

    // ========== External Functions ==========
    function createProperty(
        string calldata location,
        uint256 area,
        uint256 valuation,
        string calldata coordinates,
        string calldata description,
        uint256 totalShares
    ) external {
        uint256 propertyId = _generatePropertyId();

        _safeMint(msg.sender, propertyId);

        _propertyDetails[propertyId] = Property(location, area, valuation, coordinates, description);
        _propertyShares[propertyId] = totalShares;

        _addInitialShareholder(propertyId, msg.sender, totalShares);

        emit PropertyCreated(propertyId, msg.sender);
    }

    function transferPropertyShares(
        uint256 propertyId,
        address recipient,
        uint256 shares
    ) external {
        _validateShareTransfer(propertyId, recipient, shares);

        _shareBalances[propertyId][msg.sender] -= shares;
        _shareBalances[propertyId][recipient] += shares;
        _propertyShareholders[propertyId].add(recipient);

        // Transfer NFT ownership if sender no longer holds any shares
        if (_shareBalances[propertyId][msg.sender] == 0) {
            _transfer(msg.sender, recipient, propertyId);
        }

        emit SharesTransferred(propertyId, msg.sender, recipient, shares);
    }

    function updatePropertyValuation(uint256 propertyId, uint256 newValuation) external onlyOwner {
        require(_exists(propertyId), "Invalid property ID");

        _propertyDetails[propertyId].valuation = newValuation;

        emit PropertyValuationUpdated(propertyId, newValuation);
    }

    // ========== View Functions ==========
    function getProperty(uint256 propertyId) external view returns (Property memory) {
        return _propertyDetails[propertyId];
    }

    function getPropertyShareholders(uint256 propertyId) external view returns (address[] memory) {
        return _propertyShareholders[propertyId].values();
    }

    function getShareBalance(uint256 propertyId, address account) external view returns (uint256) {
        return _shareBalances[propertyId][account];
    }

    function getTotalShares(uint256 propertyId) external view returns (uint256) {
        return _propertyShares[propertyId];
    }

    // == Internal Helpers ==
    function _generatePropertyId() internal returns (uint256) {
        uint256 newId = _propertyIdTracker.current();
        _propertyIdTracker.increment();
        return newId;
    }

    function _addInitialShareholder(uint256 propertyId, address account, uint256 shares) internal {
        _propertyShareholders[propertyId].add(account);
        _shareBalances[propertyId][account] = shares;
    }

    function _validateShareTransfer(uint256 propertyId, address recipient, uint256 shares) internal view {
        require(_exists(propertyId), "Property does not exist");
        require(ownerOf(propertyId) == msg.sender, "Caller is not property owner");
        require(_shareBalances[propertyId][msg.sender] >= shares, "Not enough shares");
        require(recipient != address(0), "Invalid recipient");
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
