//
//  EmailTokenRepositoryProtocol.swift
//
//
//  Created by Thomas Benninghaus on 23.12.23.
//

import Foundation
import NIOCore

public protocol EmailTokenRepositoryProtocol: DBRepositoryProtocol {
    func find(token: String) -> Future<EmailToken?>
    func create(_ emailToken: EmailToken) -> Future<Void>
    func delete(_ emailToken: EmailToken) -> Future<Void>
    func find(userID: UUID) -> Future<EmailToken?>
}
