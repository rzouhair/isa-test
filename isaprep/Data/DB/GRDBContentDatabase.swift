import Foundation
import SQLite3

/// Read-only wrapper around the bundled `exam_content.sqlite`.
///
/// The bundled file is copied into Caches on first launch (and re-synced when
/// the bundle ships a newer copy) so a future remote-update mechanism can
/// swap contents without touching the app bundle.
///
/// File name is retained for git history; the underlying implementation uses
/// the system `sqlite3` C library rather than GRDB.
final class ContentDatabase {
    static let shared = ContentDatabase()

    private let lock = NSLock()
    private var handle: OpaquePointer?

    private init() {
        let fm = FileManager.default
        let cachesURL = try! fm.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dst = cachesURL.appendingPathComponent("exam_content.sqlite")

        if let src = Bundle.main.url(forResource: "exam_content", withExtension: "sqlite") {
            let bundleModified = (try? src.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let cacheModified = (try? dst.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            if !fm.fileExists(atPath: dst.path) || bundleModified > cacheModified {
                try? fm.removeItem(at: dst)
                try? fm.copyItem(at: src, to: dst)
            }
        }

        if fm.fileExists(atPath: dst.path) {
            var db: OpaquePointer?
            if sqlite3_open_v2(dst.path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK {
                self.handle = db
            } else {
                sqlite3_close(db)
            }
        }
    }

    deinit {
        if let handle { sqlite3_close(handle) }
    }

    /// Executes a read query and maps each row via the given closure.
    /// Returns an empty array when the DB is unavailable.
    func query<T>(_ sql: String, args: [SQLValue] = [], map: (SQLRow) throws -> T) throws -> [T] {
        lock.lock()
        defer { lock.unlock() }

        guard let handle else { return [] }

        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_prepare_v2(handle, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else {
            let msg = String(cString: sqlite3_errmsg(handle))
            throw SQLError.prepareFailed(msg, sql)
        }

        for (i, v) in args.enumerated() {
            let idx = Int32(i + 1)
            switch v {
            case .null: sqlite3_bind_null(stmt, idx)
            case .int(let n): sqlite3_bind_int64(stmt, idx, Int64(n))
            case .double(let d): sqlite3_bind_double(stmt, idx, d)
            case .text(let s): sqlite3_bind_text(stmt, idx, s, -1, SQLiteTransient)
            }
        }

        var rows: [T] = []
        while true {
            let step = sqlite3_step(stmt)
            if step == SQLITE_DONE { break }
            if step != SQLITE_ROW {
                let msg = String(cString: sqlite3_errmsg(handle))
                throw SQLError.stepFailed(msg)
            }
            rows.append(try map(SQLRow(stmt: stmt)))
        }
        return rows
    }
}

/// Kept for call-site compatibility with the pre-rewrite GRDB wrapper.
typealias GRDBContentDatabase = ContentDatabase

// MARK: - Minimal SQLite helpers

enum SQLValue {
    case null
    case int(Int)
    case double(Double)
    case text(String)
}

enum SQLError: Error {
    case prepareFailed(String, String)
    case stepFailed(String)
    case columnType(String)
}

/// Marker required when binding Swift strings with `sqlite3_bind_text` — tells
/// SQLite to copy the string rather than referencing the transient buffer.
let SQLiteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// Thin wrapper over a prepared-statement row for column access.
struct SQLRow {
    let stmt: OpaquePointer

    func int(_ col: Int32) -> Int { Int(sqlite3_column_int64(stmt, col)) }
    func intOrNil(_ col: Int32) -> Int? {
        sqlite3_column_type(stmt, col) == SQLITE_NULL ? nil : Int(sqlite3_column_int64(stmt, col))
    }
    func double(_ col: Int32) -> Double { sqlite3_column_double(stmt, col) }
    func text(_ col: Int32) -> String {
        guard let c = sqlite3_column_text(stmt, col) else { return "" }
        return String(cString: c)
    }
    func textOrNil(_ col: Int32) -> String? {
        sqlite3_column_type(stmt, col) == SQLITE_NULL
            ? nil
            : sqlite3_column_text(stmt, col).map { String(cString: $0) }
    }
}
