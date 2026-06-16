// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PharmaceuticalSupplyChain
 * @dev Blockchain-Based Pharmaceutical Supply Chain
 */
contract PharmaceuticalSupplyChain {

    // Medicine Batch Structure
    struct MedicineBatch {
        bytes32 batchId;
        string medicineName;
        uint256 quantity;
        uint256 manufacturingDate;

        bool isDelivered;
        bool isRecalled;

        address currentOwner;
        address manufacturer;

        uint256 lastTransferTimestamp;
    }

    // Ownership Transfer Structure
    struct OwnershipTransfer {
        address previousOwner;
        address newOwner;
        uint256 timestamp;
    }

    // Batch Storage
    mapping(bytes32 => MedicineBatch)
        public medicineBatches;

    // Transfer History
    mapping(bytes32 => OwnershipTransfer[])
        public transferHistory;

    // Track retailer stock
    mapping(address => uint256)
        public retailerStock;

    // Batch existence check
    mapping(bytes32 => bool)
        public batchExists;

    // Track retailer addresses
    mapping(address => bool)
        public retailerExists;

    address[] public retailers;

    // Store all batch IDs
    bytes32[] public allBatchIds;

    // Events
    event BatchAdded(
        bytes32 indexed batchId,
        string medicineName,
        uint256 quantity,
        address indexed manufacturer
    );

    event OwnershipTransferred(
        bytes32 indexed batchId,
        address indexed previousOwner,
        address indexed newOwner,
        uint256 timestamp
    );

    event BatchRecalled(
        bytes32 indexed batchId,
        address indexed manufacturer
    );

    /**
     * (i) Add Medicine Batch
     */
    function addMedicineBatch(
        bytes32 _batchId,
        string memory _medicineName,
        uint256 _quantity,
        uint256 _manufacturingDate
    ) public {

        require(
            !batchExists[_batchId],
            "Batch already exists"
        );

        require(
            bytes(_medicineName).length > 0,
            "Medicine name required"
        );

        require(
            _quantity > 0,
            "Quantity must be greater than zero"
        );

        medicineBatches[_batchId] =
            MedicineBatch({
                batchId: _batchId,
                medicineName: _medicineName,
                quantity: _quantity,
                manufacturingDate: _manufacturingDate,
                isDelivered: false,
                isRecalled: false,
                currentOwner: msg.sender,
                manufacturer: msg.sender,
                lastTransferTimestamp: block.timestamp
            });

        batchExists[_batchId] = true;

        allBatchIds.push(_batchId);

        emit BatchAdded(
            _batchId,
            _medicineName,
            _quantity,
            msg.sender
        );
    }

    /**
     * (ii) Transfer Ownership
     */
    function transferOwnership(
        bytes32 _batchId,
        address _newOwner
    ) public {

        require(
            batchExists[_batchId],
            "Batch does not exist"
        );

        require(
            _newOwner != address(0),
            "Invalid owner address"
        );

        MedicineBatch storage batch =
            medicineBatches[_batchId];

        // Current owner check
        require(
            msg.sender == batch.currentOwner,
            "Only current owner can transfer"
        );

        require(
            !batch.isRecalled,
            "Recalled batch cannot transfer"
        );

        // Save transfer history
        transferHistory[_batchId].push(
            OwnershipTransfer({
                previousOwner: batch.currentOwner,
                newOwner: _newOwner,
                timestamp: block.timestamp
            })
        );

        // Update owner
        address previousOwner =
            batch.currentOwner;

        batch.currentOwner = _newOwner;

        // Update delivered status
        batch.isDelivered = true;

        // Update timestamp
        batch.lastTransferTimestamp =
            block.timestamp;

        // Track retailer stock
        retailerStock[_newOwner] +=
            batch.quantity;

        // Register retailer
        if(!retailerExists[_newOwner]) {

            retailerExists[_newOwner] = true;

            retailers.push(_newOwner);
        }

        emit OwnershipTransferred(
            _batchId,
            previousOwner,
            _newOwner,
            block.timestamp
        );
    }

    /**
     * (iii) Verify Batch
     * Retrieve batch details
     */
    function verifyBatch(
        bytes32 _batchId
    )
        public
        view
        returns(
            MedicineBatch memory
        )
    {
        require(
            batchExists[_batchId],
            "Batch not found"
        );

        return medicineBatches[_batchId];
    }

    /**
     * (iii) Check Authenticity
     */
    function checkAuthenticity(
        bytes32 _batchId
    )
        public
        view
        returns(bool)
    {
        require(
            batchExists[_batchId],
            "Batch not found"
        );

        return
            !medicineBatches[_batchId]
            .isRecalled;
    }

    /**
     * (iv) Batch Recall Function
     * Only manufacturer can execute
     */
    function recallBatch(
        bytes32 _batchId
    ) public {

        require(
            batchExists[_batchId],
            "Batch not found"
        );

        MedicineBatch storage batch =
            medicineBatches[_batchId];

        require(
            msg.sender ==
            batch.manufacturer,
            "Only manufacturer can recall"
        );

        require(
            !batch.isRecalled,
            "Already recalled"
        );

        batch.isRecalled = true;

        emit BatchRecalled(
            _batchId,
            msg.sender
        );
    }

    /**
     * (v) Lowest Stock Holder
     * Find retailer with minimum stock
     */
    function findLowestStockHolder()
        public
        view
        returns(
            address,
            uint256
        )
    {
        require(
            retailers.length > 0,
            "No retailers found"
        );

        address lowestHolder =
            retailers[0];

        uint256 lowestStock =
            retailerStock[lowestHolder];

        for(
            uint256 i = 1;
            i < retailers.length;
            i++
        ) {

            if(
                retailerStock[
                    retailers[i]
                ] < lowestStock
            ) {

                lowestStock =
                    retailerStock[
                        retailers[i]
                    ];

                lowestHolder =
                    retailers[i];
            }
        }

        return (
            lowestHolder,
            lowestStock
        );
    }

    /**
     * Get Transfer History Count
     */
    function getTransferHistoryCount(
        bytes32 _batchId
    )
        public
        view
        returns(uint256)
    {
        return
            transferHistory[_batchId]
            .length;
    }

    /**
     * Total Batches
     */
    function getTotalBatches()
        public
        view
        returns(uint256)
    {
        return allBatchIds.length;
    }
}