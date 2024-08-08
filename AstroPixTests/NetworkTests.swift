//
//  NetworkTests.swift
//  AstroPixTests
//
//  Created by Peter McMaster on 06/08/2024.
//

import XCTest

enum APODNetworkTestError: Error {
    case unexpectedURLPassedThroughMockedNetworkAccess
}

class APODTestNetworkAccessor: APODNetworkAccessor {
    
    override func apiKey() async throws -> String {
        debugPrint("Using mocked API key")
        return "1234"
    }

    func testDataWithBadURL() throws -> Data {
        let testDate = Date.fromISO8601String("2024-01-01")!
        let badURL = URL(string: "http://bad.com/some/image.jpg")!
        let testData = APODResourceDetail(title: "title", explanation: "exp", date: testDate, media_type: APODSupportedMediaType.image, copyright: nil, url: badURL, thumbnail_url: nil)
        return try! APODCodableHelpers.jsonEncoder().encode(testData)
    }
    
    /// Override this to in effect mock out actual network access
    override func fetchResource(_ urlRequest: URLRequest) async throws -> Data {
        debugPrint("Using mocked fetchRequest for \(urlRequest)")
        switch urlRequest.url?.absoluteString {
        case "https://api.nasa.gov/planetary/apod?api_key=1234&thumbs=true&date=2024-01-01":
            debugPrint("Magic URL!")
            return try testDataWithBadURL()
        default:
            throw APODNetworkTestError.unexpectedURLPassedThroughMockedNetworkAccess
        }
        
    }
}

final class NetworkTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    func testHostCheckFailsOnBadHost() async throws {
        let testDate = Date.fromISO8601String("2024-01-01")!
        do {
            let _ = try await APODTestNetworkAccessor().fetchAPOD(for: testDate)
            XCTFail("Expected this call to throw")
        } catch APODNetworkError.imageNotOnExpectedHost {
            return // Expected failure
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testAPIDescramble() throws {
        let scrambledKey = "AAAAABBBBBCCCCCDDDDDEEEEEFFFFFFGGGGGGHHHHHHIIIIII\n\n"
        let descrambledKey = APODAPIKeyStore.descrambleAPIKey(scrambledKey)
        let expectedKey = "CCCCDDDDDEEEEEFFFFFFGGGGGGHHHHHHIIIIIIxx"
        XCTAssertEqual(descrambledKey, expectedKey)
    }

}
