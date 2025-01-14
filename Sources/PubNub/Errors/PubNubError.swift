//
//  PubNubError.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2019 PubNub Inc.
//  https://www.pubnub.com/
//  https://www.pubnub.com/terms
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

public struct PubNubError: Error {
  // MARK: - Properties

  /// The reason why the error occurred
  public let reason: Reason
  /// Any additional details about why the error occurred
  public let details: [String]
  /// The underlying `Error` that caused this `Error` to happen
  public let underlying: Error?

  let coorelation: [CorrelationIdentifier]
  let affected: [AffectedValue]

  /// The Endpoint category the error is associated with
  public let endpointCategory: Endpoint.Category
  /// The domain of the Endpoint the error is associated with
  public var endpointDomain: Endpoint.OperationType {
    return endpointCategory.operationCategory
  }

  /// The domain of the `Error`
  public let domain = "PubNub"
  /// The subdomain that this error can be categorized with
  public var subdomain: Domain {
    return reason.domain
  }

  // MARK: - Nested Objects

  enum CorrelationIdentifier: Hashable {
    case pubnub(UUID)
    case session(UUID)
    case request(UUID)
    case urlTask(Int)
  }

  enum AffectedValue: Hashable {
    case uuid(UUID)
    case string(String)
    case data(Data)
    case request(URLRequest)
    case response(HTTPURLResponse)
    case json(AnyJSON)
  }

  /// The PubNubError specific Domain that groups together the different Reasons
  public enum Domain: Int, Error, Hashable, Codable, LocalizedError {
    case urlCreation
    case jsonCodability
    case requestProcessing
    case crypto
    case requestTransmission
    case responseReceiving
    case responseProcessing
    case endpointResponse
    case serviceNotEnabled
    case uncategorized
    case cancellation
  }

  /// The Reason that causes a PubNubError to occur
  public enum Reason: Int, Equatable, Hashable, Codable {
    // URL Creation Errors
    case missingRequiredParameter
    case invalidEndpointType
    case missingPublishKey
    case missingSubscribeKey
    case missingPublishAndSubscribeKey

    // JSON Errors
    case jsonStringEncodingFailure
    case jsonStringDecodingFailure
    case jsonDataEncodingFailure
    case jsonDataDecodingFailure

    // Crypto
    case missingCryptoKey

    // Request Processing
    case requestMutatorFailure
    case requestRetryFailed

    // Request Transmission
    case timedOut
    case nameResolutionFailure
    case invalidURL
    case connectionFailure
    case connectionOverDataFailure
    case connectionLost
    case secureConnectionFailure
    case certificateTrustFailure

    // Cancellation
    case sessionDeinitialized
    case sessionInvalidated
    case clientCancelled
    case longPollingRestart

    // Response Received
    case badServerResponse
    case responseDecodingFailure
    case dataLengthExceedsMaximum

    // Response Processing
    case missingCriticalResponseData
    case unrecognizedStatusCode
    case malformedResponseBody

    // Endpoint Response
    case invalidArguments
    case invalidCharacter
    case invalidDevicePushToken
    case invalidSubscribeKey
    case invalidPublishKey
    case maxChannelGroupCountExceeded
    case couldNotParseRequest
    case requestContainedInvalidJSON
    case messageCountExceededMaximum
    case messageTooLong
    case invalidUUID
    case nothingToDelete

    // Service Not Enabled
    case pushNotEnabled
    case messageHistoryNotEnabled
    case messageDeletionNotEnabled

    // Uncategorized
    case unknown

    // HTTP Response Code Errors
    // Don't put non-response code errors below here
    case badRequest = 400
    case unauthorized = 401
    case forbidden = 403
    case resourceNotFound = 404
    case conflict = 409
    case preconditionFailed = 412
    case requestURITooLong = 414
    case tooManyRequests = 429
    case unsupportedType = 415
    case malformedFilterExpression = 481
    case internalServiceError = 500
    case serviceUnavailable = 503

    public var domain: PubNubError.Domain {
      switch self {
      case .missingRequiredParameter, .invalidEndpointType, .missingPublishKey,
           .missingSubscribeKey, .missingPublishAndSubscribeKey:
        return .urlCreation
      case .jsonStringEncodingFailure, .jsonStringDecodingFailure, .jsonDataEncodingFailure, .jsonDataDecodingFailure:
        return .jsonCodability
      case .missingCryptoKey:
        return .crypto
      case .requestMutatorFailure, .requestRetryFailed:
        return .requestProcessing
      case .timedOut, .nameResolutionFailure, .invalidURL,
           .connectionFailure, .connectionOverDataFailure, .connectionLost,
           .secureConnectionFailure, .certificateTrustFailure:
        return .requestTransmission
      case .clientCancelled, .sessionDeinitialized, .sessionInvalidated, .longPollingRestart:
        return .cancellation
      case .badServerResponse, .responseDecodingFailure, .dataLengthExceedsMaximum:
        return .responseReceiving
      case .missingCriticalResponseData, .unrecognizedStatusCode, .malformedResponseBody:
        return .responseProcessing
      case .invalidArguments, .invalidCharacter, .invalidDevicePushToken,
           .invalidSubscribeKey, .invalidPublishKey, .maxChannelGroupCountExceeded, .couldNotParseRequest,
           .requestContainedInvalidJSON, .serviceUnavailable, .messageCountExceededMaximum,
           .badRequest, .conflict, .preconditionFailed, .tooManyRequests, .unsupportedType,
           .unauthorized, .forbidden, .resourceNotFound, .requestURITooLong, .malformedFilterExpression,
           .internalServiceError, .messageTooLong, .invalidUUID, .nothingToDelete:
        return .endpointResponse
      case .pushNotEnabled, .messageDeletionNotEnabled, .messageHistoryNotEnabled:
        return .serviceNotEnabled
      case .unknown:
        return .uncategorized
      }
    }
  }

  // MARK: - Init

  init(
    _ reason: Reason,
    endpoint category: Endpoint.Category,
    coorelation identifiers: [CorrelationIdentifier] = [],
    underlying error: Error? = nil,
    additional details: [String] = [],
    affected values: [AffectedValue] = []
  ) {
    endpointCategory = category
    self.reason = reason
    coorelation = identifiers
    underlying = error
    self.details = details
    affected = values
  }

  init(reason: Reason) {
    self.init(reason, endpoint: Endpoint.unknown)
  }

  init(_ reason: Reason, endpoint: Endpoint, error: Error? = nil) {
    self.init(reason, endpoint: endpoint.category, underlying: error)
  }

  init(
    reason: Reason?,
    endpoint: Endpoint,
    request: URLRequest,
    response: HTTPURLResponse,
    affected details: [ErrorDetail]? = nil
  ) {
    let reasonOrResponse = reason ?? Reason(rawValue: response.statusCode)

    self.init(reasonOrResponse ?? .unrecognizedStatusCode,
              endpoint: endpoint.category,
              additional: details?.compactMap { $0.message } ?? [],
              affected: [.request(request), .response(response)])
  }

  init(router: Router, request: URLRequest, response: HTTPURLResponse) {
    self.init(PubNubError.Reason(rawValue: response.statusCode) ?? .unknown,
              endpoint: router.endpoint.category,
              affected: [.request(request), .response(response)])
  }

  init<ResponseType>(_ reason: Reason, response: Response<ResponseType>, error: Error? = nil) {
    if let error = error {
      self.init(reason,
                endpoint: response.endpoint.category,
                underlying: error,
                affected: [.request(response.request), .response(response.response)])
    }
    self.init(reason,
              endpoint: response.endpoint.category,
              affected: [.request(response.request), .response(response.response)])
  }
}

// MARK: - Hashable

extension PubNubError: Hashable {
  public static func == (lhs: PubNubError, rhs: PubNubError) -> Bool {
    return lhs.reason == rhs.reason
  }

  public func hash(into hasher: inout Hasher) {
    reason.rawValue.hash(into: &hasher)
  }
}

// MARK: - Error Coersion Helpers

extension PubNubError {
  static func convert(_ error: Error, router: Router, default reason: Reason = .unknown) -> PubNubError {
    if let pubnub = error.pubNubError {
      return pubnub
    } else if let reason = error.genericPubNubReason {
      return PubNubError(reason, endpoint: router.endpoint.category, underlying: error)
    } else {
      return PubNubError(reason, endpoint: router.endpoint.category, underlying: error)
    }
  }

  static func urlCreation(_ error: Error, router: Router) -> PubNubError {
    return PubNubError.convert(error, router: router, default: .invalidURL)
  }

  static func sessionDelegate(_ error: Error, router: Router) -> PubNubError {
    return PubNubError.convert(error, router: router, default: .unknown)
  }

  static func retry(_ error: Error, router: Router) -> PubNubError {
    return PubNubError.convert(error, router: router, default: .requestRetryFailed)
  }

  static func cancellation(_ reason: Reason?, error: Error?, router: Router) -> PubNubError {
    if let reason = reason {
      return PubNubError(reason, endpoint: router.endpoint, error: error)
    }

    if let pubnub = error?.pubNubError {
      return pubnub
    } else if let urlError = error?.urlError {
      return PubNubError(.clientCancelled, endpoint: router.endpoint.category, underlying: urlError)
    } else {
      return PubNubError(.clientCancelled, endpoint: router.endpoint.category, underlying: error)
    }
  }

  static func event(_ error: Error, endpoint category: Endpoint.Category) -> PubNubError {
    if let pubnub = error.pubNubError {
      return pubnub
    } else if let urlError = error.urlError {
      return PubNubError(.clientCancelled, endpoint: category, underlying: urlError)
    } else {
      return PubNubError(.unknown, endpoint: category, underlying: error)
    }
  }
}

// MARK: - Cross-Type Equatable

extension Optional where Wrapped == PubNubError {
  public static func == (lhs: Optional, rhs: PubNubError.Reason?) -> Bool {
    return lhs?.reason == rhs
  }

  public static func != (lhs: Optional, rhs: PubNubError.Reason?) -> Bool {
    return lhs?.reason != rhs
  }
}

extension Optional where Wrapped == PubNubError.Reason {
  public static func == (lhs: Optional, rhs: PubNubError?) -> Bool {
    return lhs == rhs?.reason
  }

  public static func != (lhs: Optional, rhs: PubNubError?) -> Bool {
    return lhs != rhs?.reason
  }
}

// MARK: - Conversions

extension PubNubError {
  public var urlError: URLError? {
    return underlying?.urlError
  }
}

extension EndpointResponseMessage {
  var pubnubReason: PubNubError.Reason? {
    switch self {
    case .acknowledge:
      return nil
    case .badRequest:
      return .badRequest
    case .conflict:
      return .conflict
    case .couldNotParseRequest:
      return .couldNotParseRequest
    case .forbidden:
      return .forbidden
    case .internalServiceError:
      return .internalServiceError
    case .invalidArguments:
      return .invalidArguments
    case .invalidCharacter:
      return .invalidCharacter
    case .invalidDeviceToken:
      return .invalidDevicePushToken
    case .invalidSubscribeKey:
      return .invalidSubscribeKey
    case .invalidPublishKey:
      return .invalidPublishKey
    case .invalidJSON:
      return .requestContainedInvalidJSON
    case .maxChannelGroupCountExceeded:
      return .maxChannelGroupCountExceeded
    case .notFound:
      return .resourceNotFound
    case .preconditionFailed:
      return .preconditionFailed
    case .pushNotEnabled:
      return .pushNotEnabled
    case .messageHistoryNotEnabled:
      return .messageHistoryNotEnabled
    case .messageDeletionNotEnabled:
      return .messageDeletionNotEnabled
    case .requestURITooLong:
      return .requestURITooLong
    case .serviceUnavailable:
      return .serviceUnavailable
    case .tooManyRequests:
      return .tooManyRequests
    case .unsupportedType:
      return .unsupportedType
    case .messageTooLong:
      return .messageTooLong
    case .invalidUUID:
      return .invalidUUID
    case .nothingToDelete:
      return .nothingToDelete
    case .unknown, .successFailedToPublishEvent:
      return nil
    }
  }
}

extension AnyJSONError {
  var pubnubReason: PubNubError.Reason {
    switch self {
    case .unknownCoding:
      return .jsonDataDecodingFailure
    case .stringCreationFailure:
      return .jsonStringEncodingFailure
    case .dataCreationFailure:
      return .jsonDataEncodingFailure
    }
  }

  var underlying: Error? {
    switch self {
    case let .unknownCoding(error):
      return error
    case let .stringCreationFailure(error):
      return error
    case let .dataCreationFailure(error):
      return error
    }
  }
}

extension URLError {
  var pubnubReason: PubNubError.Reason? {
    switch code {
    case .cancelled:
      return .clientCancelled
    case .unknown:
      return .unknown
    case .timedOut:
      return .timedOut
    case .cannotFindHost, .dnsLookupFailed:
      return .nameResolutionFailure
    case .badURL, .unsupportedURL:
      return .invalidURL
    case .cannotConnectToHost, .resourceUnavailable, .notConnectedToInternet:
      return .connectionFailure
    case .internationalRoamingOff, .callIsActive, .dataNotAllowed:
      return .connectionOverDataFailure
    case .networkConnectionLost:
      return .connectionLost
    case .secureConnectionFailed:
      return .secureConnectionFailure
    case .serverCertificateHasBadDate,
         .serverCertificateUntrusted,
         .serverCertificateHasUnknownRoot,
         .serverCertificateNotYetValid,
         .clientCertificateRejected,
         .clientCertificateRequired:
      return .certificateTrustFailure
    case .badServerResponse, .zeroByteResource:
      return .badServerResponse
    case .cannotDecodeRawData, .cannotDecodeContentData, .cannotParseResponse:
      return .responseDecodingFailure
    case .dataLengthExceedsMaximum:
      return .dataLengthExceedsMaximum
    default:
      if #available(iOS 9.0, macOS 10.11, *), code == .appTransportSecurityRequiresSecureConnection {
        return .certificateTrustFailure
      }
      return nil
    }
  }

  // swiftlint:disable:next file_length
}
