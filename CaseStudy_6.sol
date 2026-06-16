// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title HealthcareEMR
 * @dev Healthcare Electronic Medical Record System
 */
contract HealthcareEMR {

    // Patient Structure
    struct Patient {

        uint256 patientId;

        bytes32 nameHash;
        bytes32 recordHash;

        bool isActive;

        // Patient wallet address
        address patientAddress;

        // Hospital/Doctor who registered patient
        address hospitalDoctor;

        // Last update timestamp
        uint256 lastUpdated;

        // Total visits / record updates
        uint256 totalVisits;
    }

    // (i) Patient Records
    mapping(uint256 => Patient) public patients;

    // Track patient existence
    mapping(uint256 => bool) public patientExists;

    // (ii) Access Control Mapping
    mapping(uint256 => mapping(address => bool))
        public authorizedDoctors;

    uint256 public patientCount;

    // Events
    event PatientRegistered(
        uint256 indexed patientId,
        address indexed patient,
        address indexed hospitalDoctor
    );

    event AccessGranted(
        uint256 indexed patientId,
        address indexed doctor
    );

    event MedicalRecordUpdated(
        uint256 indexed patientId,
        address indexed doctor,
        uint256 timestamp
    );

    /**
     * (i) Register Patient
     * Patient ID, Name Hash, Record Hash
     * Active Status
     * Hospital/Doctor Address
     */
    function registerPatient(
        bytes32 _nameHash,
        bytes32 _recordHash
    ) public {

        require(
            _nameHash != bytes32(0),
            "Invalid name hash"
        );

        require(
            _recordHash != bytes32(0),
            "Invalid record hash"
        );

        patientCount++;

        patients[patientCount] = Patient({
            patientId: patientCount,
            nameHash: _nameHash,
            recordHash: _recordHash,
            isActive: true,
            patientAddress: msg.sender,
            hospitalDoctor: msg.sender,
            lastUpdated: block.timestamp,
            totalVisits: 0
        });

        patientExists[patientCount] = true;

        emit PatientRegistered(
            patientCount,
            msg.sender,
            msg.sender
        );
    }

    /**
     * (iii) Grant Access Function
     * Only Patient Can Grant Access
     */
    function grantAccess(
        uint256 _patientId,
        address _doctor
    ) public {

        require(
            patientExists[_patientId],
            "Patient not found"
        );

        Patient storage patient =
            patients[_patientId];

        require(
            msg.sender ==
            patient.patientAddress,
            "Only patient can grant access"
        );

        authorizedDoctors[
            _patientId
        ][_doctor] = true;

        emit AccessGranted(
            _patientId,
            _doctor
        );
    }

    /**
     * (iv) Update Medical Record
     * Only Authorized Doctors
     */
    function updateMedicalRecord(
        uint256 _patientId,
        bytes32 _newRecordHash
    ) public {

        require(
            patientExists[_patientId],
            "Patient not found"
        );

        require(
            authorizedDoctors[
                _patientId
            ][msg.sender],
            "Doctor not authorized"
        );

        Patient storage patient =
            patients[_patientId];

        require(
            patient.isActive,
            "Patient record inactive"
        );

        patient.recordHash =
            _newRecordHash;

        // Store timestamp
        patient.lastUpdated =
            block.timestamp;

        // Count visits
        patient.totalVisits++;

        emit MedicalRecordUpdated(
            _patientId,
            msg.sender,
            block.timestamp
        );
    }

    /**
     * (v) View Record
     * Only Authorized Users Allowed
     */
    function viewRecord(
        uint256 _patientId
    )
        public
        view
        returns(
            uint256,
            bytes32,
            bytes32,
            bool,
            address,
            uint256,
            uint256
        )
    {
        require(
            patientExists[_patientId],
            "Patient not found"
        );

        Patient memory patient =
            patients[_patientId];

        require(
            msg.sender ==
            patient.patientAddress ||
            authorizedDoctors[
                _patientId
            ][msg.sender],
            "Access denied"
        );

        return (
            patient.patientId,
            patient.nameHash,
            patient.recordHash,
            patient.isActive,
            patient.hospitalDoctor,
            patient.lastUpdated,
            patient.totalVisits
        );
    }

    /**
     * (vi) Count Total Visits Function
     */
    function countTotalVisits(
        uint256 _patientId
    )
        public
        view
        returns(uint256)
    {
        require(
            patientExists[_patientId],
            "Patient not found"
        );

        return
            patients[_patientId]
            .totalVisits;
    }

    /**
     * Check Doctor Authorization
     */
    function isDoctorAuthorized(
        uint256 _patientId,
        address _doctor
    )
        public
        view
        returns(bool)
    {
        return
            authorizedDoctors[
                _patientId
            ][_doctor];
    }

    /**
     * Total Patients
     */
    function getTotalPatients()
        public
        view
        returns(uint256)
    {
        return patientCount;
    }
}