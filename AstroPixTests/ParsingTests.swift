//
//  ParsingTests.swift
//  AstroPixTests
//
//  Created by Peter McMaster on 03/08/2024.
//

import XCTest

final class ParsingTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func readDecodeExampleJson(from filename: String) throws -> APODResourceMetaInfo {
        let imageWithCopyrightInfo = Bundle(for: AstroPixTests.self).url(forResource: filename, withExtension: ".json")!
        debugPrint("\(imageWithCopyrightInfo)")
        let data = try Data(contentsOf: imageWithCopyrightInfo)
        return try APODResourceDetail.decodedFrom(json: data)
    }
    
    func testTextCleanup() {
        let sampleText = "\n What's happened since the universe started? The time spiral shown here features a few notable highlights. At the spiral's center is the Big Bang, the place where time, as we know it, began about 13.8 billion years ago. Within a few billion years atoms formed, then stars formed from atoms, galaxies formed from stars and gas, our Sun formed, soon followed by our Earth, about 4.6 billion years ago.  Life on Earth begins about 3.8 billion years ago, followed by cells, then photosynthesis within a billion years.  About 1.7 billion\nyears ago, multicellular life on Earth began to flourish.  Fish began to swim about 500 million years ago, and mammals began walking on land about 200 million years ago. Humans first appeared only about 6 million years ago, and made the first cities only about 10,000 years ago.  The time spiral illustrated stops there, but human spaceflight might be added, which started only 75 years ago, and useful artificial intelligence began to take hold within only the past few years.   Explore Your Universe: Random APOD Generator\n\n"
        let result = sampleText.cleaned()
        let expectedResult = "What's happened since the universe started? The time spiral shown here features a few notable highlights. At the spiral's center is the Big Bang, the place where time, as we know it, began about 13.8 billion years ago. Within a few billion years atoms formed, then stars formed from atoms, galaxies formed from stars and gas, our Sun formed, soon followed by our Earth, about 4.6 billion years ago. Life on Earth begins about 3.8 billion years ago, followed by cells, then photosynthesis within a billion years. About 1.7 billion years ago, multicellular life on Earth began to flourish. Fish began to swim about 500 million years ago, and mammals began walking on land about 200 million years ago. Humans first appeared only about 6 million years ago, and made the first cities only about 10,000 years ago. The time spiral illustrated stops there, but human spaceflight might be added, which started only 75 years ago, and useful artificial intelligence began to take hold within only the past few years."
        XCTAssertEqual(result, expectedResult)
    }

    func testDecodeImageWithCopyrightData() throws {
        let decodedData = try readDecodeExampleJson(from: "example1")
        XCTAssertEqual(decodedData.copyright, "Tunc Tezel")
    }
    
    func testDecodeImage() throws {
        let decodedData = try readDecodeExampleJson(from: "example2")
        XCTAssertEqual(decodedData.title, "Time Spiral")
    }
    
    func testDecodeVideo() throws {
        let decodedData = try readDecodeExampleJson(from: "example3")
        XCTAssertEqual(decodedData.videoURL, URL(string: "https://www.youtube.com/embed/1R5QqhPq1Ik?rel=0"))
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
