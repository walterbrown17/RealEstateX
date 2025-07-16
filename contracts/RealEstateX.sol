// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract EstateChain is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    Counters.Counter private _idTracker;

    struct Estate {
        string location;
        uint256 area;
        uint256 price;
        string coordinates;
        string description;
    }

    mapping(uint256 => Estate) private estateData;
    mapping(uint256 => uint256) private totalUnits;
    mapping(uint256 => EnumerableSet.AddressSet) private estateOwners;
    mapping(uint256 => mapping(address => uint256)) private shareholdings;

    event EstateMinted(uint256 indexed estateId, address indexed initiator);
    event ShareTransferred(uint256 indexed estateId, address from, address to, uint256 units);
    event ValuationChanged(uint256 indexed estateId, uint256 updatedPrice);

    constructor() ERC721("EstateChain", "ECH") Ownable(msg.sender) {}

    function mintEstate(
        string calldata location,
        uint256 area,
        uint256 value,
        string calldata coordinates,
        string calldata legalText,
        uint256 units
    ) external {
        uint256 estateId = _idTracker.current();
        _idTracker.increment();

        _safeMint(msg.sender, estateId);
        _createEstate(estateId, location, area, value, coordinates, legalText, units);
        emit EstateMinted(estateId, msg.sender);
    }

    function _createEstate(
        uint256 estateId,
        string memory location,
        uint256 area,
        uint256 value,
        string memory coordinates,
        string memory legalText,
        uint256 units
    ) internal {
        estateData[estateId] = Estate(location, area, value, coordinates, legalText);
        totalUnits[estateId] = units;
        estateOwners[estateId].add(msg.sender);
        shareholdings[estateId][msg.sender] = units;
    }

    function transferShares(
        uint256 estateId,
        address recipient,
        uint256 units
    ) external {
        require(ownerOf(estateId) == msg.sender, "Only estate owner");
        require(shareholdings[estateId][msg.sender] >= units, "Not enough units");

        shareholdings[estateId][msg.sender] -= units;
        shareholdings[estateId][recipient] += units;

        if (!estateOwners[estateId].contains(recipient)) {
            estateOwners[estateId].add(recipient);
        }

        if (balanceOf(recipient) == 0) {
            _transfer(msg.sender, recipient, estateId);
        }

        emit ShareTransferred(estateId, msg.sender, recipient, units);
    }

    function modifyValuation(uint256 estateId, uint256 newPrice) external onlyOwner {
        estateData[estateId].price = newPrice;
        emit ValuationChanged(estateId, newPrice);
    }

    function getEstateInfo(uint256 estateId) external view returns (Estate memory) {
        return estateData[estateId];
    }

    function getOwners(uint256 estateId) external view returns (address[] memory) {
        return estateOwners[estateId].values();
    }

    function getUnitsHeld(uint256 estateId, address holder) external view returns (uint256) {
        return shareholdings[estateId][holder];
    }

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
