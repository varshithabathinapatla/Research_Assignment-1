// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title BookMarketplace
 * @dev Smart contract for managing a Book Marketplace
 */
contract BookMarketplace {

    struct Book {
        string title;
        uint256 price;
        bool isSold;
        address owner;
    }

    // Mapping of Book ID => Book
    mapping(uint256 => Book) public books;

    // Total number of books
    uint256 public bookCount;

    // Events
    event BookAdded(
        uint256 indexed bookId,
        string title,
        uint256 price,
        address indexed owner
    );

    event BookBought(
        uint256 indexed bookId,
        address indexed buyer,
        uint256 price
    );

    event RefundIssued(
        address indexed buyer,
        uint256 refundAmount
    );

    /**
     * @dev Add a new book
     * @param _title Book title
     * @param _price Book price in wei
     */
    function addBook(
        string memory _title,
        uint256 _price
    ) public {

        require(
            bytes(_title).length > 0,
            "Title cannot be empty"
        );

        require(
            _price > 0,
            "Price must be greater than zero"
        );

        bookCount++;

        books[bookCount] = Book({
            title: _title,
            price: _price,
            isSold: false,
            owner: msg.sender
        });

        emit BookAdded(
            bookCount,
            _title,
            _price,
            msg.sender
        );
    }

    /**
     * @dev Retrieve book details
     * @param _bookId Book ID
     */
    function getBook(
        uint256 _bookId
    )
        public
        view
        returns (
            string memory title,
            uint256 price,
            bool isSold,
            address owner
        )
    {
        require(
            _bookId > 0 &&
            _bookId <= bookCount,
            "Invalid Book ID"
        );

        Book memory book = books[_bookId];

        return (
            book.title,
            book.price,
            book.isSold,
            book.owner
        );
    }

    /**
     * @dev Buy a book
     * @param _bookId Book ID
     */
    function buyBook(
        uint256 _bookId
    ) public payable {

        require(
            _bookId > 0 &&
            _bookId <= bookCount,
            "Invalid Book ID"
        );

        Book storage book = books[_bookId];

        require(
            !book.isSold,
            "Book already sold"
        );

        require(
            msg.sender != book.owner,
            "Owner cannot buy own book"
        );

        require(
            msg.value >= book.price,
            "Insufficient payment"
        );

        address previousOwner = book.owner;

        uint256 refundAmount =
            msg.value - book.price;

        // Transfer ownership
        book.owner = msg.sender;
        book.isSold = true;

        // Pay seller
        (bool success, ) =
            payable(previousOwner).call{
                value: book.price
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

        emit BookBought(
            _bookId,
            msg.sender,
            book.price
        );
    }

    /**
     * @dev Check whether book is sold
     */
    function isBookSold(
        uint256 _bookId
    )
        public
        view
        returns(bool)
    {
        require(
            _bookId > 0 &&
            _bookId <= bookCount,
            "Invalid Book ID"
        );

        return books[_bookId].isSold;
    }

    /**
     * @dev Get owner of a book
     */
    function getBookOwner(
        uint256 _bookId
    )
        public
        view
        returns(address)
    {
        require(
            _bookId > 0 &&
            _bookId <= bookCount,
            "Invalid Book ID"
        );

        return books[_bookId].owner;
    }

    /**
     * @dev Get total books in marketplace
     */
    function getTotalBooks()
        public
        view
        returns(uint256)
    {
        return bookCount;
    }
}