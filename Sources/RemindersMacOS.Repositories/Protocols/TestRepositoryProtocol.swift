//
//  TestRepositoryProtocol.swift
//
//
//  Created by Thomas Benninghaus on 25.05.24.
//

import Vapor

public protocol TestRepositoryProtocol: AnyObject {
    var eventLoop: EventLoop { get set }
}

public extension TestRepositoryProtocol where Self: RequestServiceProtocol {
    func `for`(_ req: Request) -> Self {
        self.eventLoop = req.eventLoop
        return self
    }
}
