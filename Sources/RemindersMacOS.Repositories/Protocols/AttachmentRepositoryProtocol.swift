//
//  AttachmentRepositoryProtocol.swift
//  
//
//  Created by Thomas Benninghaus on 28.01.24.
//

import Vapor
import Fluent

public protocol AttachmentRepositoryProtocol: DBRepositoryProtocol, AttachmentRepositoryMockProtocol {
    func create(_ attachment: AttachmentModel) -> Future<Void>
    func delete(id: UUID) -> Future<Void>
    func all(for taskId: UUID) -> Future<[AttachmentModel]>
    func find(id: UUID?) -> Future<AttachmentModel?>
    func set(_ attachment: AttachmentModel) -> Future<Void>
    func set<Field>(_ field: KeyPath<AttachmentModel, Field>, to value: Field.Value, for attachmentID: UUID) -> Future<Void> where Field: QueryableProperty, Field.Model == AttachmentModel
    func count(for taskId: UUID) -> Future<Int>
}

public protocol AttachmentRepositoryMockProtocol {
    func getDemo(_ exampleNo: Int, taskId: UUID) -> [AttachmentModel]
    func createDemo(_ exampleNo: Int, taskId: UUID) -> Future<[AttachmentModel]>
}
