// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Rent-by-the-year name registry
contract NameRegistry {
    uint256 public constant GRACE = 30 days;

    struct Record {
        address owner;
        address addr;
        uint64 expires;
    }

    address public admin;
    uint256 public yearlyFee;
    mapping(bytes32 => Record) public records;

    event Registered(string name, address indexed owner, uint256 expires);
    event Renewed(string name, uint256 expires);
    event AddressSet(string name, address addr);
    event Transferred(string name, address indexed to);

    error InvalidName();
    error Unavailable();
    error NotOwner();
    error Expired();
    error InsufficientPayment();
    error TransferFailed();

    constructor(uint256 _yearlyFee) {
        admin = msg.sender;
        yearlyFee = _yearlyFee;
    }

    function valid(string memory name) public pure returns (bool) {
        bytes memory b = bytes(name);
        if (b.length < 3 || b.length > 32) return false;
        for (uint256 i; i < b.length; ++i) {
            bytes1 c = b[i];
            bool ok = (c >= 0x61 && c <= 0x7a) || (c >= 0x30 && c <= 0x39) || c == 0x2d;
            if (!ok) return false;
        }
        return b[0] != 0x2d && b[b.length - 1] != 0x2d;
    }

    function available(string memory name) public view returns (bool) {
        return records[keccak256(bytes(name))].expires + GRACE < block.timestamp;
    }

    function register(string calldata name, uint256 years_) external payable {
        if (!valid(name) || years_ == 0) revert InvalidName();
        if (!available(name)) revert Unavailable();
        uint256 expires = block.timestamp + years_ * 365 days;
        records[keccak256(bytes(name))] = Record(msg.sender, msg.sender, uint64(expires));
        _charge(years_);
        emit Registered(name, msg.sender, expires);
    }

    function renew(string calldata name, uint256 years_) external payable {
        Record storage r = records[keccak256(bytes(name))];
        if (r.owner == address(0) || r.expires + GRACE < block.timestamp) revert Expired();
        r.expires += uint64(years_ * 365 days);
        _charge(years_);
        emit Renewed(name, r.expires);
    }

    function setAddress(string calldata name, address addr) external {
        Record storage r = _owned(name);
        r.addr = addr;
        emit AddressSet(name, addr);
    }

    function transfer(string calldata name, address to) external {
        Record storage r = _owned(name);
        r.owner = to;
        emit Transferred(name, to);
    }

    function resolve(string calldata name) external view returns (address) {
        Record storage r = records[keccak256(bytes(name))];
        return r.expires >= block.timestamp ? r.addr : address(0);
    }

    function setFee(uint256 fee) external {
        if (msg.sender != admin) revert NotOwner();
        yearlyFee = fee;
    }

    function withdraw(address to) external {
        if (msg.sender != admin) revert NotOwner();
        (bool ok,) = to.call{value: address(this).balance}("");
        if (!ok) revert TransferFailed();
    }

    function _owned(string calldata name) internal view returns (Record storage r) {
        r = records[keccak256(bytes(name))];
        if (r.owner != msg.sender) revert NotOwner();
        if (r.expires < block.timestamp) revert Expired();
    }

    function _charge(uint256 years_) internal {
        uint256 cost = yearlyFee * years_;
        if (msg.value < cost) revert InsufficientPayment();
        if (msg.value > cost) {
            (bool ok,) = msg.sender.call{value: msg.value - cost}("");
            if (!ok) revert TransferFailed();
        }
    }
}
