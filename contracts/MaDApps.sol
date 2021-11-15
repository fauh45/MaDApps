// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

contract MaDApps {
    struct Document {
        bool exist;
        string document_hash;
        string document_type;
    }

    address private owner;
    mapping(string => mapping(string => Document)) private documents;

    event ValidatedHash(
        string indexed NIM,
        string documentHash,
        string indexed documentType
    );
    event InvalidatedHash(
        string indexed NIM,
        string documentHash,
        string indexed documentType
    );

    constructor() {
        owner = msg.sender;
    }

    modifier ownerOnly() {
        require(msg.sender == owner, "User are not the owner");

        _;
    }

    function addValidatedHash(
        string memory _NIM,
        string memory _documentHash,
        string memory _documentType
    ) external ownerOnly {
        documents[_NIM][_documentHash] = Document(
            true,
            _documentHash,
            _documentType
        );

        emit ValidatedHash(_NIM, _documentHash, _documentType);
    }

    function invalidateHash(string memory _NIM, string memory _documentHash)
        external
        ownerOnly
    {
        Document memory existingDocument = documents[_NIM][_documentHash];
        existingDocument.exist = false;

        documents[_NIM][_documentHash] = existingDocument;

        emit InvalidatedHash(
            _NIM,
            _documentHash,
            existingDocument.document_type
        );
    }

    function validateHash(string memory _NIM, string memory _documentHash)
        external
        view
        returns (Document memory)
    {
        return documents[_NIM][_documentHash];
    }
}
