/**
 * @description       :
 * @author            : Mayank Singh
 * @group             :
 * @last modified on  : 05-02-2025
 * @last modified by  : Mayank Singh
 **/
public with sharing class AWSS3Manager {
    
    public static void createBucket(String bucketName, String recordId, String region) {
        bucketName = bucketName.toLowerCase().replaceAll(' ', '-') + '-' + recordId.toLowerCase();
        System.debug('Bucket Name: ' + bucketName);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:AWSS3Cred'+'/'+ EncodingUtil.urlEncode(bucketName, 'UTF-8'));
        req.setMethod('PUT');
        
        String requestBody = '<?xml version="1.0" encoding="UTF-8"?>' +
            '<CreateBucketConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">' +
            '<LocationConstraint>'+region+'</LocationConstraint>' +
            '</CreateBucketConfiguration>';
        
        if(String.isNotBlank(region) && !region.equalsIgnoreCase('us-east-1')){
            req.setBody(requestBody);
        }
        try {
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                System.debug('Bucket created successfully: ' + bucketName);
                Account acc  = new Account(Id = recordId, S3BucketName__c = bucketName);
                update acc;
            } else if (res.getStatusCode() == 403) {
                System.debug('Access denied to create bucket: ' + bucketName);
            } else {
                System.debug('Error creating bucket: ' + res.getStatus());
            }
        }
        catch (System.Exception e) {
            System.debug('Error creating bucket: ' + e.getMessage());
        }
    }
    
    public static void createFolderInsideBucket(String bucketName, String folderName) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:AWSS3Cred'+'/'+ EncodingUtil.urlEncode(bucketName, 'UTF-8') + '/' + EncodingUtil.urlEncode(folderName, 'UTF-8') + '/');
        req.setMethod('PUT');
        req.setHeader('Content-Length', String.valueOf(0));
        
        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                System.debug(folderName+ 'Folder created successfully in bucket: ' + bucketName);
            } else {
                System.debug('Error creating folder: ' + res.getStatus());
            }
        }
        catch (System.Exception e) {
            System.debug('Error creating folder: ' + e.getMessage());
        }
    }
    
    public static void uploadFile(Id recordId, String endpoint) {
        ContentVersion version = [
            SELECT Title, FileExtension, FileType, VersionData
            FROM   ContentVersion
            WHERE  Id = :recordId
            LIMIT  1
        ];
        
        String fileName = version.Title + '.' + version.FileExtension;
        String encodedFileName = EncodingUtil.urlEncode(fileName, 'UTF-8');
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:AWSS3Cred/' + endpoint + '/' + encodedFileName);
        req.setMethod('PUT');
        req.setBodyAsBlob(version.VersionData);
        
        System.debug('Endpoint: ' + req.getEndpoint());
        System.debug('File Name: ' + fileName);
        
        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                System.debug('File uploaded successfully → ' + fileName);
            } else {
                System.debug('Upload failed: HTTP ' + res.getStatus() + ' body=' + res.getBody());
            }
        } catch (Exception ex) {
            System.debug('Callout exception: ' + ex.getMessage());
            throw ex;
        }
    }
}