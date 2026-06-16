// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EnergyTrading
 * @dev Peer-to-Peer Renewable Energy Trading System
 */
contract EnergyTrading {

    // Producer Structure
    struct EnergyProducer {
        uint256 energyUnitsAvailable;
        uint256 pricePerUnit;
        bool isActive;
        address producerAddress;
    }

    // Transaction Structure
    struct Transaction {
        address producer;
        address consumer;
        uint256 energyUnits;
        uint256 totalPrice;
        uint256 timestamp;
    }

    // (ii)(a) Energy Balance Mapping
    mapping(address => uint256) public energyBalance;

    // (ii)(b) Energy Credits Mapping
    mapping(address => uint256) public energyCredits;

    // Producer Details
    mapping(address => EnergyProducer) public producers;

    // Track total energy sold by producer
    mapping(address => uint256) public totalEnergySold;

    // Transaction Index Mapping
    mapping(uint256 => Transaction) public transactionIndex;

    // Producer List
    address[] public producerAddresses;

    // Check Producer Existence
    mapping(address => bool) public isProducer;

    // Transaction Counter
    uint256 public transactionCount;

    // Events
    event ProducerRegistered(
        address indexed producer,
        uint256 energyUnits,
        uint256 pricePerUnit
    );

    event EnergyPurchased(
        address indexed producer,
        address indexed consumer,
        uint256 energyUnits,
        uint256 totalPrice
    );

    event RefundIssued(
        address indexed consumer,
        uint256 refundAmount
    );

    event ProducerDeactivated(
        address indexed producer
    );

    /**
     * (i) Register Energy Producer
     */
    function registerProducer(
        uint256 _energyUnits,
        uint256 _pricePerUnit
    ) public {

        require(
            _energyUnits > 0,
            "Energy units must be greater than zero"
        );

        require(
            _pricePerUnit > 0,
            "Price per unit must be greater than zero"
        );

        if(!isProducer[msg.sender]) {

            producerAddresses.push(
                msg.sender
            );

            isProducer[msg.sender] = true;
        }

        producers[msg.sender] = EnergyProducer({
            energyUnitsAvailable: _energyUnits,
            pricePerUnit: _pricePerUnit,
            isActive: true,
            producerAddress: msg.sender
        });

        emit ProducerRegistered(
            msg.sender,
            _energyUnits,
            _pricePerUnit
        );
    }

    /**
     * (iii) Buy Energy Function
     */
    function buyEnergy(
        address _producer,
        uint256 _energyUnits
    ) public payable {

        require(
            isProducer[_producer],
            "Invalid producer"
        );

        require(
            msg.sender != _producer,
            "Producer cannot buy own energy"
        );

        require(
            _energyUnits > 0,
            "Energy units must be greater than zero"
        );

        EnergyProducer storage producer =
            producers[_producer];

        require(
            producer.isActive,
            "Producer inactive"
        );

        require(
            producer.energyUnitsAvailable >=
            _energyUnits,
            "Insufficient energy available"
        );

        uint256 totalPrice =
            _energyUnits *
            producer.pricePerUnit;

        // Consumer payment check
        require(
            msg.value >= totalPrice,
            "Insufficient payment"
        );

        uint256 refundAmount =
            msg.value - totalPrice;

        // Deduct energy units
        producer.energyUnitsAvailable -=
            _energyUnits;

        // Update energy balance
        energyBalance[msg.sender] +=
            _energyUnits;

        // Update producer credits
        energyCredits[_producer] +=
            totalPrice;

        // Track total energy sold
        totalEnergySold[_producer] +=
            _energyUnits;

        // Store transaction history
        transactionIndex[
            transactionCount
        ] = Transaction({
            producer: _producer,
            consumer: msg.sender,
            energyUnits: _energyUnits,
            totalPrice: totalPrice,
            timestamp: block.timestamp
        });

        transactionCount++;

        // Transfer payment
        (bool success, ) =
            payable(_producer).call{
                value: totalPrice
            }("");

        require(
            success,
            "Payment transfer failed"
        );

        // Refund extra payment
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

        emit EnergyPurchased(
            _producer,
            msg.sender,
            _energyUnits,
            totalPrice
        );
    }

    /**
     * Get Producer Information
     */
    function getProducerInfo(
        address _producer
    )
        public
        view
        returns(
            uint256,
            uint256,
            bool,
            address
        )
    {
        EnergyProducer memory p =
            producers[_producer];

        return (
            p.energyUnitsAvailable,
            p.pricePerUnit,
            p.isActive,
            p.producerAddress
        );
    }

    /**
     * (iv) Get Transaction Details
     */
    function getTransaction(
        uint256 _index
    )
        public
        view
        returns(
            address,
            address,
            uint256,
            uint256,
            uint256
        )
    {
        Transaction memory t =
            transactionIndex[_index];

        return (
            t.producer,
            t.consumer,
            t.energyUnits,
            t.totalPrice,
            t.timestamp
        );
    }

    /**
     * (v) Max Energy Seller Function
     * Finds producer who sold
     * maximum energy units.
     */
    function findMaxEnergySeller()
        public
        view
        returns(
            address,
            uint256
        )
    {
        require(
            producerAddresses.length > 0,
            "No producers found"
        );

        address maxProducer =
            producerAddresses[0];

        uint256 maxSold =
            totalEnergySold[maxProducer];

        for(
            uint256 i = 1;
            i < producerAddresses.length;
            i++
        ) {

            address producer =
                producerAddresses[i];

            if(
                totalEnergySold[producer]
                > maxSold
            ) {

                maxSold =
                    totalEnergySold[
                        producer
                    ];

                maxProducer =
                    producer;
            }
        }

        return (
            maxProducer,
            maxSold
        );
    }

    /**
     * Deactivate Producer
     */
    function deactivateProducer()
        public
    {
        require(
            isProducer[msg.sender],
            "Not a producer"
        );

        producers[msg.sender]
            .isActive = false;

        emit ProducerDeactivated(
            msg.sender
        );
    }

    /**
     * Total Producers
     */
    function getTotalProducers()
        public
        view
        returns(uint256)
    {
        return producerAddresses.length;
    }
}