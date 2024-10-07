//
//  RefreshTokenRepositoryProtocol.swift
//  
//
//  Created by Thomas Benninghaus on 23.12.23.
//

import Foundation
import NIOCore

public protocol RefreshTokenRepositoryProtocol: DBRepositoryProtocol {
    func create(_ token: RefreshToken) -> Future<Void>
    func find(id: UUID?) -> Future<RefreshToken?>
    func find(token: String) -> Future<RefreshToken?>
    func delete(_ token: RefreshToken) -> Future<Void>
    func count() -> Future<Int>
    func delete(for userID: UUID) -> Future<Void>
}
