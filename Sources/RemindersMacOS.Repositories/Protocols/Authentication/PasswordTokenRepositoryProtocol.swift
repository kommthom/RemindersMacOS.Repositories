//
//  PasswordTokenRepositoryProtocol.swift
//  
//
//  Created by Thomas Benninghaus on 23.12.23.
//

import Foundation
import NIOCore

public protocol PasswordTokenRepositoryProtocol: DBRepositoryProtocol {
    func find(userID: UUID) -> Future<PasswordToken?>
    func find(token: String) -> Future<PasswordToken?>
    func count() -> Future<Int>
    func create(_ passwordToken: PasswordToken) -> Future<Void>
    func delete(_ passwordToken: PasswordToken) -> Future<Void>
    func delete(for userID: UUID) -> Future<Void>
}
