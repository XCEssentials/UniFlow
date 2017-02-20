//
//  Action.swift
//  MKHUniFlow
//
//  Created by Maxim Khatskevich on 2/20/17.
//  Copyright © 2017 Maxim Khatskevich. All rights reserved.
//

import Foundation

//===

public
struct Action<UFLModel>
{
    let id: String
    
    let body: (UFLModel, (Mutations<UFLModel>) -> Void, @escaping (() -> Action<UFLModel>) -> Void) throws -> Void
}

//===

public
protocol ActionContext {}

//===

public
extension ActionContext
{
    static
    func action<UFLModel>(
        _ name: String = #function,
        _ body: @escaping (UFLModel, (Mutations<UFLModel>) -> Void, @escaping (() -> Action<UFLModel>) -> Void) throws -> Void
        ) -> Action<UFLModel>
    {
        return Action(id: "\(self).\(name)", body: body)
    }
}
