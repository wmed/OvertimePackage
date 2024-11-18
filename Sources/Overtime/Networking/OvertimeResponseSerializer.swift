//
//  OvertimeResponseSerializer.swift
//  
//
//  Created by Daniel Baldonado on 8/23/24.
//

import Alamofire
import Foundation

internal final class OvertimeResponseSerializer: ResponseSerializer {
    struct ResponseObject {
        let data: Data
        let reponse: HTTPURLResponse
    }
    let dataPreprocessor: DataPreprocessor
    let emptyResponseCodes: Set<Int>
    let emptyRequestMethods: Set<HTTPMethod>

    /// Creates a `DataResponseSerializer` using the provided parameters.
    ///
    /// - Parameters:
    ///   - dataPreprocessor:    `DataPreprocessor` used to prepare the received `Data` for serialization.
    ///   - emptyResponseCodes:  The HTTP response codes for which empty responses are allowed. `[204, 205]` by default.
    ///   - emptyRequestMethods: The HTTP request methods for which empty responses are allowed. `[.head]` by default.
    init(dataPreprocessor: DataPreprocessor = DataResponseSerializer.defaultDataPreprocessor,
                emptyResponseCodes: Set<Int> = DataResponseSerializer.defaultEmptyResponseCodes,
                emptyRequestMethods: Set<HTTPMethod> = DataResponseSerializer.defaultEmptyRequestMethods) {
        self.dataPreprocessor = dataPreprocessor
        self.emptyResponseCodes = emptyResponseCodes
        self.emptyRequestMethods = emptyRequestMethods
    }

    func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> ResponseObject {
        guard error == nil else { throw error! }
        guard let response else { throw RequestError.noResponse }

        guard var data, !data.isEmpty else {
            guard emptyResponseAllowed(forRequest: request, response: response) else {
                throw AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)
            }

            return ResponseObject(data: Data(), reponse: response)
        }

        data = try dataPreprocessor.preprocess(data)

        return ResponseObject(data: data, reponse: response)
    }
}

extension ResponseSerializer where Self == DataResponseSerializer {
    /// Provides a default `DataResponseSerializer` instance.
    public static var data: DataResponseSerializer { DataResponseSerializer() }

    /// Creates a `DataResponseSerializer` using the provided parameters.
    ///
    /// - Parameters:
    ///   - dataPreprocessor:    `DataPreprocessor` used to prepare the received `Data` for serialization.
    ///   - emptyResponseCodes:  The HTTP response codes for which empty responses are allowed. `[204, 205]` by default.
    ///   - emptyRequestMethods: The HTTP request methods for which empty responses are allowed. `[.head]` by default.
    ///
    /// - Returns:               The `DataResponseSerializer`.
    public static func data(dataPreprocessor: DataPreprocessor = DataResponseSerializer.defaultDataPreprocessor,
                            emptyResponseCodes: Set<Int> = DataResponseSerializer.defaultEmptyResponseCodes,
                            emptyRequestMethods: Set<HTTPMethod> = DataResponseSerializer.defaultEmptyRequestMethods) -> DataResponseSerializer {
        DataResponseSerializer(dataPreprocessor: dataPreprocessor,
                               emptyResponseCodes: emptyResponseCodes,
                               emptyRequestMethods: emptyRequestMethods)
    }
}
