//
//  DatabaseManager.swift
//  bluetooth
//
//  Created by Ray chai on 2024/6/13.
//

import Foundation
import SQLite3

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: OpaquePointer?

    private init() {
        openDatabase()
        createTable()
    }

    private func openDatabase() {
        let fileURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("Devices.sqlite")

        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("Error opening database")
        }
    }

    private func createTable() {
        let createTableString = """
        CREATE TABLE IF NOT EXISTS Devices(
        id TEXT PRIMARY KEY,
        name TEXT);
        """
        var createTableStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                print("Devices table created.")
            } else {
                print("Devices table could not be created.")
            }
        } else {
            print("CREATE TABLE statement could not be prepared.")
        }
        sqlite3_finalize(createTableStatement)
    }

    func insertDevice(id: String, name: String) {
        let insertStatementString = "INSERT INTO Devices (id, name) VALUES (?, ?);"
        var insertStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(insertStatement, 1, id, -1, nil)
            sqlite3_bind_text(insertStatement, 2, name, -1, nil)
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                print("Successfully inserted row.")
            } else {
                print("Could not insert row.")
            }
        } else {
            print("INSERT statement could not be prepared.")
        }
        sqlite3_finalize(insertStatement)
    }

    func fetchDeviceName(id: String) -> String? {
        let queryStatementString = "SELECT name FROM Devices WHERE id = ?;"
        var queryStatement: OpaquePointer?
        var name: String?
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(queryStatement, 1, id, -1, nil)
            if sqlite3_step(queryStatement) == SQLITE_ROW {
                name = String(describing: String(cString: sqlite3_column_text(queryStatement, 0)))
            } else {
                print("Query returned no results.")
            }
        } else {
            print("SELECT statement could not be prepared.")
        }
        sqlite3_finalize(queryStatement)
        return name
    }
}
