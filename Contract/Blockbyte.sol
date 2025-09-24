// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Blockbyte - Decentralized File Storage Systems
 * @dev Smart contract for managing decentralized file storage and sharing
 */
contract BlockByte {
    
    struct FileData {
        uint256 id;
        string fileName;
        string fileHash;
        uint256 fileSize;
        address owner;
        uint256 uploadTime;
        bool isPublic;
        uint256 accessCount;
    }
    
    // State variables
    mapping(uint256 => FileData) public files;
    mapping(address => uint256[]) public userFiles;
    mapping(uint256 => mapping(address => bool)) public sharedAccess;
    
    uint256 public totalFiles;
    uint256 private fileCounter;
    
    // Events
    event FileUploaded(uint256 indexed fileId, string fileName, address indexed owner);
    event FileShared(uint256 indexed fileId, address indexed owner, address indexed recipient);
    event FileAccessed(uint256 indexed fileId, address indexed accessor);
    
    // Modifiers
    modifier onlyOwner(uint256 _fileId) {
        require(files[_fileId].owner == msg.sender, "Only file owner can perform this action");
        _;
    }
    
    modifier validFile(uint256 _fileId) {
        require(_fileId > 0 && _fileId <= fileCounter, "Invalid file ID");
        _;
    }
    
    modifier hasAccess(uint256 _fileId) {
        require(
            files[_fileId].owner == msg.sender || 
            files[_fileId].isPublic || 
            sharedAccess[_fileId][msg.sender],
            "Access denied"
        );
        _;
    }
    
    /**
     * @dev Core Function 1: Upload a file to the blockchain
     * @param _fileName Name of the file
     * @param _fileHash Hash of the file (IPFS or content hash)
     * @param _fileSize Size of the file in bytes
     * @param _isPublic Whether the file should be publicly accessible
     * @return fileId The unique identifier of the uploaded file
     */
    function uploadFile(
        string memory _fileName,
        string memory _fileHash,
        uint256 _fileSize,
        bool _isPublic
    ) external returns (uint256) {
        require(bytes(_fileName).length > 0, "File name cannot be empty");
        require(bytes(_fileHash).length > 0, "File hash cannot be empty");
        require(_fileSize > 0, "File size must be greater than zero");
        
        fileCounter++;
        totalFiles++;
        
        FileData memory newFile = FileData({
            id: fileCounter,
            fileName: _fileName,
            fileHash: _fileHash,
            fileSize: _fileSize,
            owner: msg.sender,
            uploadTime: block.timestamp,
            isPublic: _isPublic,
            accessCount: 0
        });
        
        files[fileCounter] = newFile;
        userFiles[msg.sender].push(fileCounter);
        
        emit FileUploaded(fileCounter, _fileName, msg.sender);
        
        return fileCounter;
    }
    
    /**
     * @dev Core Function 2: Share a file with another user
     * @param _fileId ID of the file to share
     * @param _recipient Address of the user to share with
     */
    function shareFile(uint256 _fileId, address _recipient) 
        external 
        validFile(_fileId) 
        onlyOwner(_fileId) 
    {
        require(_recipient != address(0), "Invalid recipient address");
        require(_recipient != msg.sender, "Cannot share with yourself");
        
        sharedAccess[_fileId][_recipient] = true;
        
        emit FileShared(_fileId, msg.sender, _recipient);
    }
    
    /**
     * @dev Core Function 3: Access/download a file
     * @param _fileId ID of the file to access
     * @return fileName Name of the file
     * @return fileHash Hash of the file
     * @return fileSize Size of the file
     * @return owner Owner of the file
     */
    function accessFile(uint256 _fileId) 
        external 
        validFile(_fileId) 
        hasAccess(_fileId)
        returns (
            string memory fileName,
            string memory fileHash,
            uint256 fileSize,
            address owner
        ) 
    {
        FileData storage file = files[_fileId];
        file.accessCount++;
        
        emit FileAccessed(_fileId, msg.sender);
        
        return (
            file.fileName,
            file.fileHash,
            file.fileSize,
            file.owner
        );
    }
    
    /**
     * @dev Get file information (metadata only)
     * @param _fileId ID of the file
     */
    function getFileInfo(uint256 _fileId) 
        external 
        view 
        validFile(_fileId) 
        returns (
            string memory fileName,
            uint256 fileSize,
            address owner,
            uint256 uploadTime,
            bool isPublic,
            uint256 accessCount
        ) 
    {
        FileData memory file = files[_fileId];
        return (
            file.fileName,
            file.fileSize,
            file.owner,
            file.uploadTime,
            file.isPublic,
            file.accessCount
        );
    }
    
    /**
     * @dev Get all file IDs owned by a user
     * @param _user Address of the user
     * @return Array of file IDs
     */
    function getUserFiles(address _user) external view returns (uint256[] memory) {
        return userFiles[_user];
    }
    
    /**
     * @dev Check if user has access to a file
     * @param _fileId ID of the file
     * @param _user Address of the user
     * @return Boolean indicating access permission
     */
    function checkAccess(uint256 _fileId, address _user) 
        external 
        view 
        validFile(_fileId) 
        returns (bool) 
    {
        return files[_fileId].owner == _user || 
               files[_fileId].isPublic || 
               sharedAccess[_fileId][_user];
    }
    
    /**
     * @dev Revoke shared access to a filefds
     * @param _fileId ID of the file
     * @param _user Address of the user to revoke access from
     */
    function revokeAccess(uint256 _fileId, address _user) 
        external 
        validFile(_fileId) 
        onlyOwner(_fileId) 
    {
        require(sharedAccess[_fileId][_user], "User does not have shared access");
        sharedAccess[_fileId][_user] = false;
    }
    
    /**
     * @dev Get total number of files in the system
     * @return Total file count
     */
    function getTotalFiles() external view returns (uint256) {
        return totalFiles;
    }
}
