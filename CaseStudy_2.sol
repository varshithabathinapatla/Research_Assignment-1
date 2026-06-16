// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title BankingSystem
 * @dev Banking Smart Contract for managing customer accounts
 */
contract BankingSystem {

    // (i) Balance Ledger Mapping
    mapping(address => uint256) public balanceLedger;

    // Address Index Mapping
    mapping(address => uint256) public addressIndex;

    // Tracks total deposited/transferred amount
    mapping(address => uint256) public transactionAmount;

    // Stores all customer addresses
    address[] public customerAddresses;

    // Checks whether customer already exists
    mapping(address => bool) public customerExists;

    // Events
    event DepositMade(
        address indexed customer,
        uint256 amount
    );

    event WithdrawalMade(
        address indexed customer,
        uint256 amount
    );

    event TransferMade(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    /**
     * (ii) Deposit Function
     * Handles deposits and updates Balance Ledger
     * and Address Index.
     */
    function deposit() public payable {

        require(
            msg.value > 0,
            "Deposit amount must be greater than 0"
        );

        // Register new customer
        if(!customerExists[msg.sender]) {

            addressIndex[msg.sender] =
                customerAddresses.length;

            customerAddresses.push(msg.sender);

            customerExists[msg.sender] = true;
        }

        balanceLedger[msg.sender] += msg.value;

        // Track total deposited amount
        transactionAmount[msg.sender] += msg.value;

        emit DepositMade(
            msg.sender,
            msg.value
        );
    }

    /**
     * (iii) Get Balance Function
     */
    function getBalance(
        address _customer
    )
        public
        view
        returns(uint256)
    {
        return balanceLedger[_customer];
    }

    /**
     * (iv) Withdraw Function
     */
    function withdraw(
        uint256 _amount
    ) public {

        require(
            _amount > 0,
            "Amount must be greater than 0"
        );

        require(
            balanceLedger[msg.sender] >= _amount,
            "Insufficient balance"
        );

        balanceLedger[msg.sender] -= _amount;

        (bool success, ) =
            payable(msg.sender).call{
                value: _amount
            }("");

        require(
            success,
            "Withdrawal failed"
        );

        emit WithdrawalMade(
            msg.sender,
            _amount
        );
    }

    /**
     * (iv) Transfer Function
     */
    function transfer(
        address _to,
        uint256 _amount
    ) public {

        require(
            _to != address(0),
            "Invalid recipient"
        );

        require(
            _amount > 0,
            "Amount must be greater than 0"
        );

        require(
            balanceLedger[msg.sender] >= _amount,
            "Insufficient balance"
        );

        // Register recipient if new
        if(!customerExists[_to]) {

            addressIndex[_to] =
                customerAddresses.length;

            customerAddresses.push(_to);

            customerExists[_to] = true;
        }

        balanceLedger[msg.sender] -= _amount;
        balanceLedger[_to] += _amount;

        // Track transferred amount
        transactionAmount[_to] += _amount;

        emit TransferMade(
            msg.sender,
            _to,
            _amount
        );
    }

    /**
     * (v) Min Deposit Function
     * Finds the account with minimum deposited
     * or transferred amount.
     */
    function minDeposit()
        public
        view
        returns(
            address,
            uint256
        )
    {
        require(
            customerAddresses.length > 0,
            "No customers found"
        );

        address minAddress =
            customerAddresses[0];

        uint256 minAmount =
            transactionAmount[minAddress];

        for(
            uint256 i = 1;
            i < customerAddresses.length;
            i++
        ) {

            if(
                transactionAmount[
                    customerAddresses[i]
                ] < minAmount
            ) {

                minAmount =
                    transactionAmount[
                        customerAddresses[i]
                    ];

                minAddress =
                    customerAddresses[i];
            }
        }

        return (
            minAddress,
            minAmount
        );
    }

    /**
     * Get Total Customers
     */
    function getTotalCustomers()
        public
        view
        returns(uint256)
    {
        return customerAddresses.length;
    }

    /**
     * Get Customer Address by Index
     */
    function getCustomerByIndex(
        uint256 _index
    )
        public
        view
        returns(address)
    {
        require(
            _index < customerAddresses.length,
            "Invalid index"
        );

        return customerAddresses[_index];
    }

    /**
     * Get all customer addresses
     */
    function getAllCustomers()
        public
        view
        returns(address[] memory)
    {
        return customerAddresses;
    }
}