// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IoTDataMarketplace
 * @dev IoT Device Data Marketplace Smart Contract
 */
contract IoTDataMarketplace {

    // Device Structure
    struct Device {
        uint256 deviceId;
        string deviceType;
        uint256 dataPrice;
        bool isActive;
        address owner;
    }

    // Access Record Structure
    struct AccessRecord {
        address buyer;
        uint256 purchaseTime;
        bool hasAccess;
    }

    // (ii)(a) Mapping to store device details
    mapping(uint256 => Device) public devices;

    // (ii)(b) Mapping to store devices owned by user
    mapping(address => uint256[]) public userDevices;

    // Mapping to track data access
    mapping(uint256 => mapping(address => AccessRecord))
        public deviceAccess;

    // Device Counter
    uint256 public deviceCount;

    // Events
    event DeviceRegistered(
        uint256 indexed deviceId,
        string deviceType,
        uint256 dataPrice,
        address indexed owner
    );

    event DataAccessPurchased(
        uint256 indexed deviceId,
        address indexed buyer,
        uint256 amount
    );

    event RefundIssued(
        address indexed buyer,
        uint256 refundAmount
    );

    event DeviceDeactivated(
        uint256 indexed deviceId,
        address indexed owner
    );

    /**
     * (i) Register Device
     */
    function registerDevice(
        string memory _deviceType,
        uint256 _dataPrice
    ) public {

        require(
            bytes(_deviceType).length > 0,
            "Device type cannot be empty"
        );

        require(
            _dataPrice > 0,
            "Price must be greater than zero"
        );

        deviceCount++;

        devices[deviceCount] = Device({
            deviceId: deviceCount,
            deviceType: _deviceType,
            dataPrice: _dataPrice,
            isActive: true,
            owner: msg.sender
        });

        userDevices[msg.sender].push(deviceCount);

        emit DeviceRegistered(
            deviceCount,
            _deviceType,
            _dataPrice,
            msg.sender
        );
    }

    /**
     * (iii) Get Device Data
     */
    function getDeviceData(
        uint256 _deviceId
    )
        public
        view
        returns (
            uint256,
            string memory,
            uint256,
            bool,
            address
        )
    {
        require(
            _deviceId > 0 &&
            _deviceId <= deviceCount,
            "Invalid Device ID"
        );

        Device memory d = devices[_deviceId];

        return (
            d.deviceId,
            d.deviceType,
            d.dataPrice,
            d.isActive,
            d.owner
        );
    }

    /**
     * (iv) Buy Data Access
     */
    function buyDataAccess(
        uint256 _deviceId
    ) public payable {

        require(
            _deviceId > 0 &&
            _deviceId <= deviceCount,
            "Invalid Device ID"
        );

        Device storage device =
            devices[_deviceId];

        require(
            device.isActive,
            "Device is inactive"
        );

        require(
            msg.sender != device.owner,
            "Owner cannot buy own data"
        );

        require(
            msg.value >= device.dataPrice,
            "Insufficient payment"
        );

        uint256 refundAmount =
            msg.value - device.dataPrice;

        // Update Access Status
        deviceAccess[_deviceId][msg.sender] =
            AccessRecord({
                buyer: msg.sender,
                purchaseTime: block.timestamp,
                hasAccess: true
            });

        // Transfer payment to owner
        (bool success, ) =
            payable(device.owner).call{
                value: device.dataPrice
            }("");

        require(
            success,
            "Payment transfer failed"
        );

        // Refund excess amount
        if(refundAmount > 0){

            (bool refundSuccess, ) =
                payable(msg.sender).call{
                    value: refundAmount
                }("");

            require(
                refundSuccess,
                "Refund failed"
            );

            emit RefundIssued(
                msg.sender,
                refundAmount
            );
        }

        emit DataAccessPurchased(
            _deviceId,
            msg.sender,
            device.dataPrice
        );
    }

    /**
     * Check Access Status
     */
    function hasDataAccess(
        uint256 _deviceId,
        address _buyer
    )
        public
        view
        returns(bool)
    {
        require(
            _deviceId > 0 &&
            _deviceId <= deviceCount,
            "Invalid Device ID"
        );

        return
            deviceAccess[_deviceId][_buyer]
            .hasAccess;
    }

    /**
     * (v) Deactivate Device
     * Only owner can deactivate
     */
    function deactivateDevice(
        uint256 _deviceId
    ) public {

        require(
            _deviceId > 0 &&
            _deviceId <= deviceCount,
            "Invalid Device ID"
        );

        Device storage device =
            devices[_deviceId];

        require(
            msg.sender == device.owner,
            "Only owner can deactivate"
        );

        require(
            device.isActive,
            "Already inactive"
        );

        device.isActive = false;

        emit DeviceDeactivated(
            _deviceId,
            msg.sender
        );
    }

    /**
     * Get Devices Owned By User
     */
    function getUserDevices(
        address _owner
    )
        public
        view
        returns(uint256[] memory)
    {
        return userDevices[_owner];
    }

    /**
     * Total Registered Devices
     */
    function getTotalDevices()
        public
        view
        returns(uint256)
    {
        return deviceCount;
    }
}