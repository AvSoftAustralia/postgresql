import XCTest
@testable import PostgreSQL

class ArrayTests: XCTestCase {
    static let allTests = [
        ("testIntArray", testIntArray),
        ("testStringArray", testStringArray),
        ("test2DArray", test2DArray),
        ("testArrayWithNull", testArrayWithNull),
    ]
    
    var postgreSQL: PostgreSQL.Database!

    override func setUp() {
        postgreSQL = PostgreSQL.Database.makeTestConnection()
    }
    
    func testIntArray() throws {
        let rows = [
            [1,2,3,4,5],
            [123],
            [],
            [-1,2,-3,4,-5],
            [-1,2,-3,4,-5,-1,2,-3,4,-5,-1,2,-3,4,-5,-1,2,-3,4,-5],
        ]
        
        try postgreSQL.execute("DROP TABLE IF EXISTS foo")
        try postgreSQL.execute("CREATE TABLE foo (id serial, int_array int[])")
        for row in rows {
            try postgreSQL.execute("INSERT INTO foo VALUES (DEFAULT, $1)", [row.makeNode()])
        }
        
        let result = try postgreSQL.execute("SELECT * FROM foo ORDER BY id ASC")
        XCTAssertEqual(result.count, rows.count)
        for (i, resultRow) in result.enumerated() {
            let intArray = resultRow["int_array"]
            XCTAssertNotNil(intArray?.nodeArray)
            XCTAssertEqual(intArray!.nodeArray!.flatMap { $0.int }, rows[i])
        }
    }
    
    func testStringArray() throws {
        let rows = [
            ["A simple test string", "Another string", "", "Great testing skills"],
            [""],
            [],
            ["Vapor is amazing 🤖"],
            ["🙀", "👽", "👀", "🐶", "🐱", "😂", "👻", "👍", "🙉"],
        ]
        
        try postgreSQL.execute("DROP TABLE IF EXISTS foo")
        try postgreSQL.execute("CREATE TABLE foo (id serial, string_array text[])")
        for row in rows {
            try postgreSQL.execute("INSERT INTO foo VALUES (DEFAULT, $1)", [row.makeNode()])
        }
        
        let result = try postgreSQL.execute("SELECT * FROM foo ORDER BY id ASC")
        XCTAssertEqual(result.count, rows.count)
        for (i, resultRow) in result.enumerated() {
            let stringArray = resultRow["string_array"]
            XCTAssertNotNil(stringArray?.nodeArray)
            XCTAssertEqual(stringArray!.nodeArray!.flatMap { $0.string }, rows[i])
        }
    }
    
    func test2DArray() throws {
        let rows = [
            [[1, 2], [3, 4], [5, 6]],
            [[1], [2], [3], [4]],
            [],
            [[1, 2, 3]],
            [[1, 2, 3, 4], [5, 6, 7, 8]],
        ]
        
        try postgreSQL.execute("DROP TABLE IF EXISTS foo")
        try postgreSQL.execute("CREATE TABLE foo (id serial, int_array int[][])")
        for row in rows {
            let node = try Node.array(row.map { try $0.makeNode() })
            try postgreSQL.execute("INSERT INTO foo VALUES (DEFAULT, $1)", [node])
        }
        
        let result = try postgreSQL.execute("SELECT * FROM foo ORDER BY id ASC")
        XCTAssertEqual(result.count, rows.count)
        for (i, resultRow) in result.enumerated() {
            let intArray = resultRow["int_array"]
            XCTAssertNotNil(intArray?.nodeArray)
            
            let result = intArray!.nodeArray!.flatMap { $0.nodeArray?.flatMap { $0.int } }
            for (i, rowArray) in rows[i].enumerated() {
                XCTAssertEqual(result[i], rowArray)
            }
        }
    }
    
    func testArrayWithNull() throws {
        let rows = [
            [1,Node.null,3,4,5],
            [123],
            [],
            [-1,2,Node.null,4,-5],
            [-1,2,-3,Node.null,-5,-1,2,-3,4,Node.null,-1,2,-3,Node.null,-5,-1,2,-3,4,-5],
            [Node.null],
        ]
        
        try postgreSQL.execute("DROP TABLE IF EXISTS foo")
        try postgreSQL.execute("CREATE TABLE foo (id serial, int_array int[])")
        for row in rows {
            try postgreSQL.execute("INSERT INTO foo VALUES (DEFAULT, $1)", [row.makeNode()])
        }
        
        let result = try postgreSQL.execute("SELECT * FROM foo ORDER BY id ASC")
        XCTAssertEqual(result.count, rows.count)
        for (i, resultRow) in result.enumerated() {
            let intArray = resultRow["int_array"]
            XCTAssertNotNil(intArray?.nodeArray)
            XCTAssertEqual(intArray!.nodeArray!, rows[i])
        }
    }
}
