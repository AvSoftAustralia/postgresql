import XCTest
@testable import PostgreSQL

class ArrayTests: XCTestCase {
    static let allTests = [
        ("testIntArray", testIntArray),
        ("testStringArray", testStringArray),
        ("testBoolArray", testBoolArray),
        ("testBytesArray", testBytesArray),
        ("testUnsupportedObjectArray", testUnsupportedObjectArray),
        ("test2DArray", test2DArray),
        ("testArrayWithNull", testArrayWithNull),
    ]
    
    var postgreSQL: PostgreSQL.Database!

    override func setUp() {
        postgreSQL = PostgreSQL.Database.makeTest()
    }
    
    func testIntArray() throws {
        let conn = try postgreSQL.makeConnection()
        
        let rows = [
            [1,2,3,4,5],
            [123],
            [],
            [-1,2,-3,4,-5],
            [-1,2,-3,4,-5,-1,2,-3,4,-5,-1,2,-3,4,-5,-1,2,-3,4,-5],
        ]
        
        try conn.execute("DROP TABLE IF EXISTS foo")
        try conn.execute("CREATE TABLE foo (id serial, int_array int[])")
        for row in rows {
            try conn.execute("INSERT INTO foo VALUES (DEFAULT, $1)", [row.makeNode(in: nil)])
        }
        
        let result = try conn.execute("SELECT * FROM foo ORDER BY id ASC").array ?? []
        XCTAssertEqual(result.count, rows.count)
        for (i, resultRow) in result.enumerated() {
            let intArray = resultRow["int_array"]
            XCTAssertNotNil(intArray?.array)
            XCTAssertEqual(intArray!.array!.flatMap { $0.int }, rows[i])
        }
    }
    
    func testStringArray() throws {
        let conn = try postgreSQL.makeConnection()
        
        let rows = [
            ["A simple test string", "Another string", "", "Great testing skills"],
            [""],
            [],
            ["Vapor is amazing 🤖"],
            ["🙀", "👽", "👀", "🐶", "🐱", "😂", "👻", "👍", "🙉"],
        ]
        
        try conn.execute("DROP TABLE IF EXISTS foo")
        try conn.execute("CREATE TABLE foo (id serial, string_array text[])")
        for row in rows {
            try conn.execute("INSERT INTO foo VALUES (DEFAULT, $1)", [row.makeNode(in: nil)])
        }
        
        let result = try conn.execute("SELECT * FROM foo ORDER BY id ASC").array ?? []
        XCTAssertEqual(result.count, rows.count)
        for (i, resultRow) in result.enumerated() {
            let stringArray = resultRow["string_array"]
            XCTAssertNotNil(stringArray?.array)
            XCTAssertEqual(stringArray!.array!.flatMap { $0.string }, rows[i])
        }
    }
    
    func testBoolArray() throws {
        let conn = try postgreSQL.makeConnection()
        
        let rows = [
            [true, false, true, true, false],
            [false],
            [],
            [true],
            [true, true, true],
            [false, true],
        ]
        
        try conn.execute("DROP TABLE IF EXISTS foo")
        try conn.execute("CREATE TABLE foo (id serial, bool_array bool[])")
        for row in rows {
            try conn.execute("INSERT INTO foo VALUES (DEFAULT, $1)", [row.makeNode(in: nil)])
        }
        
        let result = try conn.execute("SELECT * FROM foo ORDER BY id ASC").array ?? []
        XCTAssertEqual(result.count, rows.count)
        for (i, resultRow) in result.enumerated() {
            let boolArray = resultRow["bool_array"]
            XCTAssertNotNil(boolArray?.array)
            XCTAssertEqual(boolArray!.array!.flatMap { $0.bool }, rows[i])
        }
    }
    
    func testBytesArray() throws {
        let conn = try postgreSQL.makeConnection()
        
        let rows: [[Node]] = [
            [.bytes([0x00, 0x12, 0x00]), .bytes([]), .bytes([0x12, 0x54, 0x1f, 0xaa, 0x9a, 0xa8, 0xcd]), .bytes([0x00])],
            [.bytes([0x12, 0x34, 0x56, 0x78, 0x9A])],
            [],
            [.bytes([0x98, 0x76])],
            [.bytes([0x11, 0x00]), .bytes([0x22]), .bytes([0x33]), .bytes([0x44]), .bytes([0x55])],
        ]
        
        try conn.execute("DROP TABLE IF EXISTS foo")
        try conn.execute("CREATE TABLE foo (id serial, byte_array bytea[])")
        for row in rows {
            try conn.execute("INSERT INTO foo VALUES (DEFAULT, $1)", [row.makeNode(in: nil)])
        }
        
        let result = try conn.execute("SELECT * FROM foo ORDER BY id ASC").array ?? []
        XCTAssertEqual(result.count, rows.count)
        for (i, resultRow) in result.enumerated() {
            let byteArray = resultRow["byte_array"]
            XCTAssertNotNil(byteArray?.array)
            XCTAssertEqual(byteArray!.array!.flatMap { node in
                return node
            }, rows[i])
        }
    }
    
    func testUnsupportedObjectArray() throws {
        let conn = try postgreSQL.makeConnection()
        
        let rows: [[[String:Int]]] = [
            [["key":1],["key":2],["key":3],["key":4],["key":5]],
            [["key":123]],
            [],
            [[:]],
            [["key":-1],["key":2],["key":-3],["key":4],["key":-5]],
        ]
        
        try conn.execute("DROP TABLE IF EXISTS foo")
        try conn.execute("CREATE TABLE foo (id serial, int_array int[])")
        for row in rows {
            try conn.execute("INSERT INTO foo VALUES (DEFAULT, $1)", [row.map { try $0.makeNode(in: nil) }.makeNode(in: nil)])
        }
        
        let result = try conn.execute("SELECT * FROM foo ORDER BY id ASC").array ?? []
        XCTAssertEqual(result.count, rows.count)
        for (i, resultRow) in result.enumerated() {
            let intArray = resultRow["int_array"]
            XCTAssertNotNil(intArray?.array)
            XCTAssertEqual(intArray!.array!.count, rows[i].count)
            XCTAssertEqual(intArray!.array!.flatMap { $0.int }, [])
            XCTAssertEqual(intArray!.array!.flatMap { $0.isNull ? Node.null : nil }.count, rows[i].count)
        }
    }
    
    func test2DArray() throws {
        let conn = try postgreSQL.makeConnection()
        
        let rows = [
            [[1, 2], [3, 4], [5, 6]],
            [[1], [2], [3], [4]],
            [],
            [[1, 2, 3]],
            [[1, 2, 3, 4], [5, 6, 7, 8]],
        ]
        
        try conn.execute("DROP TABLE IF EXISTS foo")
        try conn.execute("CREATE TABLE foo (id serial, int_array int[][])")
        for row in rows {
            let node = try Node.array(row.map { try $0.makeNode(in: nil) })
            try conn.execute("INSERT INTO foo VALUES (DEFAULT, $1)", [node])
        }
        
        let result = try conn.execute("SELECT * FROM foo ORDER BY id ASC").array ?? []
        XCTAssertEqual(result.count, rows.count)
        for (i, resultRow) in result.enumerated() {
            let intArray = resultRow["int_array"]
            XCTAssertNotNil(intArray?.array)
            
            let result = intArray!.array!.flatMap { $0.array?.flatMap { $0.int } }
            for (i, rowArray) in rows[i].enumerated() {
                XCTAssertEqual(result[i], rowArray)
            }
        }
    }
    
    func testArrayWithNull() throws {
        let conn = try postgreSQL.makeConnection()
        
        let rows = [
            [1,Node.null,3,4,5],
            [123],
            [],
            [-1,2,Node.null,4,-5],
            [-1,2,-3,Node.null,-5,-1,2,-3,4,Node.null,-1,2,-3,Node.null,-5,-1,2,-3,4,-5],
            [Node.null],
        ]
        
        try conn.execute("DROP TABLE IF EXISTS foo")
        try conn.execute("CREATE TABLE foo (id serial, int_array int[])")
        for row in rows {
            try conn.execute("INSERT INTO foo VALUES (DEFAULT, $1)", [row.makeNode(in: nil)])
        }
        
        let result = try conn.execute("SELECT * FROM foo ORDER BY id ASC").array ?? []
        XCTAssertEqual(result.count, rows.count)
        for (i, resultRow) in result.enumerated() {
            let intArray = resultRow["int_array"]
            XCTAssertNotNil(intArray?.array)
            XCTAssertEqual(intArray!.array!, rows[i])
        }
    }
}
