//
//  PlistStorage.swift
//  LocalStorage
//
//  Created by 정준영 on 2025/8/3.
//

import Foundation

/// 파일 시스템을 사용하여 **Property List** 데이터를 저장하는 `KeyValueStorage` 구현체
public struct PlistStorage: KeyValueStorage, BundleResourceLoadable {
    private let fileManager: FileManager
    private let documentsDirectory: URL

    public init() {
        self.fileManager = FileManager.default
        self.documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func fileURL<K: StorageKey>(for key: K) -> URL {
        let fileName = "\(key.rawValue).plist"
        return documentsDirectory.appendingPathComponent(fileName)
    }

    public func save<T: Codable, K: StorageKey>(_ data: T, forKey key: K) async throws {
        let fileURL = fileURL(for: key)
        let encodedData = try PropertyListEncoder().encode(data)
        try encodedData.write(to: fileURL, options: .atomic)
    }

    public func load<T: Codable, K: StorageKey>(_ type: T.Type, fromKey key: K) async throws -> T {
        let fileURL = fileURL(for: key)
        guard let data = try? Data(contentsOf: fileURL) else { throw StorageError.keyNotFound }
        do {
            return try PropertyListDecoder().decode(type, from: data)
        } catch {
            throw StorageError.decodingFailed(error)
        }
    }

    public func exists<K: StorageKey>(forKey key: K) async -> Bool {
        fileManager.fileExists(atPath: fileURL(for: key).path)
    }

    public func delete<K: StorageKey>(forKey key: K) async throws {
        let fileURL = fileURL(for: key)
        if await exists(forKey: key) {
            try fileManager.removeItem(at: fileURL)
        }
    }

    public func loadFromBundle<T: Codable>(_ type: T.Type, fileName: String, in bundle: Bundle = .main) async throws -> T {
        guard let url = bundle.url(forResource: fileName, withExtension: "plist") else {
            throw StorageError.bundleResourceNotFound
        }
        do {
            let data = try Data(contentsOf: url)
            return try PropertyListDecoder().decode(type, from: data)
        } catch {
            throw StorageError.decodingFailed(error)
        }
    }
}

