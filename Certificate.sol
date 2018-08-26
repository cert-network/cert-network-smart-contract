pragma solidity ^0.4.24;

/*
 *
 * @author Wasuwat Limsuparhat
 * @created 25/08/2018 at Pizza Hackathon, Bangkok, Thailand
 * 
 */

contract CertificateContract{
    struct Certificate {
        bytes32 id;
        address certCreator;
        string certName;
        string certIndustry;
        string certDescription;
        string issuedDate;
        string expiredDate;
        string approvedBy;
        bool isApproved;
    }
    
    struct User {
        uint id;
        string name;
        string passport;
        bool doesExist;
    }
    
    struct Approver {
        uint id;
        string name;
        string approvableIndustry;
        bool doesExist;
    }
    
    uint approverId = 0;
    mapping(address => Approver) public approverList;
    
    uint userId = 0;
    mapping(address => User) public userList;
    
    uint certIndex = 0;
    mapping(uint => Certificate) public certificateList;
    mapping(address => bytes32[]) public certificateListByAddress;
    mapping(bytes32 => Certificate) public certificateListById;
    
    
    event AddAprrover(uint _id);
    event CreateUser(uint _id);
    event CreateCertificate(bytes32 _certId);
    event VerifyCertificate(bytes32 _certId);
    
    address administrator;
        
    constructor() public payable{
        // administrator is contract owner/deployer
        administrator = msg.sender;
    }
    
    function addAprrover(string _name, address _approverAddress, string _approvableIndustry) public{
        // check if address is admin 
        require(msg.sender == administrator);
        // check if approver does not exists
        require(approverList[msg.sender].doesExist == false, "Approver already exists");
        
        uint apprId = approverId++;
        approverList[_approverAddress] = Approver(apprId, _name, _approvableIndustry, true);
        
        emit AddAprrover(apprId);
    }
    
    function createUser(string _name, string _passport) public {
        // make sure that user does not exist
        require(userList[msg.sender].doesExist == false, "Already registered");
        
        uint uid = userId++;
        userList[msg.sender] = User(uid, _name, _passport, true);
        
        emit CreateUser(uid);
    }

    function createCertificate(string _name, string _industry, string _description, string _expiredDate) public{
        bytes32 uniqueCertId = keccak256(abi.encodePacked(_name, msg.sender));
        
        Certificate memory newCert = Certificate(uniqueCertId, msg.sender, _name, _industry, _description, "", _expiredDate, "", false);
        certificateList[certIndex] = newCert;
        certificateListByAddress[msg.sender].push(uniqueCertId);
        certificateListById[uniqueCertId] = newCert;
        
        certIndex++;
        
        emit CreateCertificate(uniqueCertId);
    }
    
    function verifyCertificate(address _certCreator, bytes32 _certId, string _issuedDate, string _industry, bool _isValidCert) public {
        // cannot verify yourself!
        require(_certCreator != msg.sender);
        // msg.sender needs to be in approverList
        require(approverList[msg.sender].doesExist == true, "Approver is not in the list");
        // approver should have same category as cert
        require(keccak256(abi.encodePacked(_industry)) == keccak256(abi.encodePacked(approverList[msg.sender].approvableIndustry)), "Approver cannot approve this category.");
        
        Approver memory currentApprove = approverList[msg.sender];
        Certificate memory tobeVerifyCert = certificateListById[_certId];
        tobeVerifyCert.issuedDate = _issuedDate;
        tobeVerifyCert.isApproved = _isValidCert;
        tobeVerifyCert.approvedBy = currentApprove.name;
        
        bytes32[] memory certIds = certificateListByAddress[_certCreator];
        uint certIdsIndx = 0;
        while(certIdsIndx < certIds.length){
            if(certificateListByAddress[_certCreator][certIdsIndx] == tobeVerifyCert.id){
                certificateListById[tobeVerifyCert.id] = tobeVerifyCert;
            }
            certIdsIndx++;
        }
        
        uint certListIndx = 0;
        bool didUpdateCertState = false;
        while(!didUpdateCertState){
            if(certificateList[certListIndx].id == _certId){
                certificateList[certListIndx] = tobeVerifyCert;
                didUpdateCertState = true;
            }
            certListIndx++;
        }
        emit VerifyCertificate(_certId);
    }
}