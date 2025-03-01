//
//  ResponseOperator.swift
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

// MARK: - Response Decoder

/// The object responsible for decoding the raw response data
public protocol ResponseDecoder where Payload: Codable {
  associatedtype Payload

  /// The method called when attempting to decode the response data for a given Endpoint
  ///
  /// - Parameters:
  ///   - response: The raw `Response` to be decoded
  ///   - decoder: The `ResponseDecoder` used to decode the raw response data
  /// - Returns: The decoded payload or the error that occurred during the decoding process
  func decode(response: Response<Data>) -> Result<Response<Payload>, Error>

  /// The method called when attempting to decode the response error data for a given Endpoint
  ///
  /// - Parameters:
  ///   - endpoint: The endpoint that was requested
  ///   - request: The `URLRequest` that failed
  ///   - response: The `HTTPURLResponse` that was returned
  ///   - for: The `ResponseDecoder` used to decode the raw response data
  /// - Returns: The `PubNubError` that represents the response error
  func decodeError(endpoint: Endpoint, request: URLRequest, response: HTTPURLResponse, for data: Data) -> PubNubError?

  /// The method called when attempting to decode the response error data for a given Endpoint
  ///
  /// - Parameters:
  ///   - response: The response to be decrypted
  /// - Returns: The decrypted Payload or an Error
  func decrypt(response: Response<Payload>) -> Result<Response<Payload>, Error>
}

extension ResponseDecoder {
  func decodeError(endpoint: Endpoint, request: URLRequest, response: HTTPURLResponse, for data: Data) -> PubNubError? {
    return decodeDefaultError(endpoint: endpoint, request: request, response: response, for: data)
  }

  func decode(response: Response<Data>) -> Result<Response<Payload>, Error> {
    do {
      let decodedPayload = try Constant.jsonDecoder.decode(Payload.self, from: response.payload)

      let decodedResponse = Response<Payload>(router: response.router,
                                              request: response.request,
                                              response: response.response,
                                              data: response.data,
                                              payload: decodedPayload)

      return .success(decodedResponse)
    } catch {
      return .failure(PubNubError(.jsonDataDecodingFailure, response: response, error: error))
    }
  }

  func decrypt(response: Response<Payload>) -> Result<Response<Payload>, Error> {
    return .success(response)
  }

  func decodeDefaultError(
    endpoint: Endpoint,
    request: URLRequest,
    response: HTTPURLResponse,
    for data: Data
  ) -> PubNubError? {
    // Attempt to decode based on general system response payload
    let generalErrorPayload = try? Constant.jsonDecoder.decode(GenericServicePayloadResponse.self, from: data)

    return PubNubError(reason: generalErrorPayload?.pubnubReason,
                       endpoint: endpoint, request: request, response: response,
                       affected: generalErrorPayload?.details)
  }
}

// MARK: - Request: Response Handling

extension Request {
  /// The directions on how to process the response when it comes back from the `Endpoint`
  ///
  /// - Parameters:
  ///   - on: The queue the completion block will be returned on
  ///   - decoder: The decoder used to determine the response type
  ///   - completion: The completion block being returned with the decode response data or the error that occurred
  public func response<D: ResponseDecoder>(
    on queue: DispatchQueue = .main,
    decoder responseDecoder: D,
    completion: @escaping (Result<Response<D.Payload>, Error>) -> Void
  ) {
    appendResponseCompletion { result in
      queue.async {
        completion(
          result.flatMap { response in
            // Decode the data response into the correct data type
            responseDecoder.decode(response: response).flatMap { decoded in
              // Do any decryption of the decoded data result
              responseDecoder.decrypt(response: decoded)
            }
          }
        )
      }
    }
  }

  func appendResponseCompletion(_ closure: @escaping (Result<Response<Data>, Error>) -> Void) {
    // Add the completion closure to the request and wait for it to complete
    atomicState.lockedWrite { mutableState in
      mutableState.responseCompletionClosure = closure
    }
  }

  func processResponseCompletion(_ result: Result<Response<Data>, Error>) {
    // Request is now complete, so fire the stored completion closure
    var responseCompletion: ((Result<Response<Data>, Error>) -> Void)?

    atomicState.lockedWrite { state in
      responseCompletion = state.responseCompletionClosure

      if state.taskState.canTransition(to: .finished) {
        state.taskState = .finished
      }
    }

    responseCompletion?(result)
  }
}
