//
//  AWSS3Client.swift
//  TreeTracker
//
//  Created by Alex Cornforth on 19/09/2020.
//  Copyright © 2020 Greenstand. All rights reserved.
//

import Foundation
import AWSS3

class AWSS3Client {

    enum AWSS3ClientError: Error {
        case jsonEncodingError
    }

    private lazy var s3Client: AWSS3 = {
        return AWSS3.s3(forKey: Constants.s3ServiceKey)
    }()

    private lazy var transferUtility: AWSS3TransferUtility? = {
        return AWSS3TransferUtility.s3TransferUtility(forKey: Constants.transferUtilityKey)
    }()

    func registerS3CLient() {
        AWSS3.register(with: serviceConfiguration, forKey: Constants.s3ServiceKey)
        AWSS3TransferUtility.register(with: serviceConfiguration, forKey: Constants.transferUtilityKey)
    }

    func uploadImage(imageData: Data, uuid: String, latitude: Double, logitude: Double, completion: @escaping (Result<String, Error>) -> Void) {
        let key = "\(formattedDate())_\(latitude)_\(logitude)_\(UUID().uuidString)_\(uuid)"
//        put(data: imageData, bucketName: Constants.BucketName.images, key: key, acl: .publicRead, completion: completion)
        transfer(data: imageData, bucketName: Constants.BucketName.images, key: key, acl: .publicRead, completion: completion)
    }

    func uploadBundle(jsonBundle: String, bundleId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let key = "\(formattedDate())_\(UUID().uuidString)_\(bundleId)"

        guard let jsonData = jsonBundle.data(using: .utf8) else {
            completion(.failure(AWSS3ClientError.jsonEncodingError))
            return
        }

//        put(data: jsonData, bucketName: Constants.BucketName.batchUploads, key: key, acl: nil, completion: completion)
        transfer(data: jsonData, bucketName: Constants.BucketName.batchUploads, key: key, acl: nil, completion: completion)
    }

    func interceptApplication(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        AWSS3TransferUtility.interceptApplication(
            application,
            handleEventsForBackgroundURLSession: identifier,
            completionHandler: completionHandler
        )
    }
}

// MARK: - Private
private extension AWSS3Client {

    var credentialsProvider: AWSCredentialsProvider {
        return AWSCognitoCredentialsProvider(
            regionType: AWSCredentials.regionType,
            identityPoolId: AWSCredentials.identityPoolId
        )
    }

    var serviceConfiguration: AWSServiceConfiguration {
        return AWSServiceConfiguration(
            region: AWSCredentials.regionType,
            credentialsProvider: credentialsProvider
        )
    }

    func formattedDate(forDate date: Date = Date()) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd.HH.mm.ss"
        return dateFormatter.string(from: date)
    }

    func put(data: Data, bucketName: String, key: String, acl: AWSS3ObjectCannedACL?, completion: @escaping (Result<String, Error>) -> Void) {

        guard let request = AWSS3PutObjectRequest() else {
            return
        }

        request.bucket = bucketName
        request.body = data
        request.key = key
        request.contentLength = NSNumber(value: data.count)

        if let acl = acl {
            request.acl = acl
        }

        s3Client.putObject(request) { (_, error) in

            if let error = error {
                completion(.failure(error))
                return
            }
            let url = "https://\(bucketName).s3.\(AWSCredentials.regionString).amazonaws.com/\(key)"
            completion(.success(url))
        }
    }

    func transfer(data: Data, bucketName: String, key: String, acl: AWSS3ObjectCannedACL?, completion: @escaping (Result<String, Error>) -> Void) {
        transferUtility?.uploadData(data, bucket: bucketName, key: key, contentType: "", expression: nil, completionHandler: { (_, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            let url = "https://\(bucketName).s3.\(AWSCredentials.regionString).amazonaws.com/\(key)"
            completion(.success(url))
        })
    }
}

// MARK: - Constants
private extension AWSS3Client {

    struct Constants {

        static let s3ServiceKey: String = "treetrackerS3Service"
        static let transferUtilityKey: String = "treetrackerS3TransferUtility"

        struct BucketName {
            static let images: String = Configuration.AWS.imagesBucketName
            static let batchUploads: String = Configuration.AWS.batchUploadsBucketName
        }
    }

    struct AWSCredentials {
        static let identityPoolId: String = Configuration.AWS.identityPoolId
        static let regionType: AWSRegionType = Configuration.AWS.region
        static let regionString: String = Configuration.AWS.regionString
    }
}
