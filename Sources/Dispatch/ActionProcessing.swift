/*
 
 MIT License
 
 Copyright (c) 2016 Maxim Khatskevich (maxim@khatskevi.ch)
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 
 */

import Foundation

//===

public
extension Dispatcher.Proxy
{
    public
    func submit(_ action: Action)
    {
        DispatchQueue.main.async {
            
            // we add this action to queue async-ly,
            // to make sure it will be processed AFTER
            // current execution is complete,
            // that allows to submit an Action from
            // another Action safely
            
            self.dispatcher.process(action)
        }
    }
}

//===

extension Dispatcher
{
    func process(_ action: Action)
    {
        do
        {
            if
                let mutation = try action.body(state, proxy.submit)
            {
                // NOTE: if body will throw,
                // then mutations will not be applied to global model
                
                process(mutation)
            }
            
            //---
            
            onDidProcessAction?(action)
        }
        catch
        {
            // action has thrown,
            // will NOT notify subscribers
            // about attempt to process this action
            
            onDidRejectAction?(action, error)
        }
    }
    
    //===
    
    func process(_ mutation: GlobalMutationExt)
    {
        state = mutation.apply(state)
        
        //---
        
        addMiddlewareIfNeeded(mutation)
        
        //---
        
        middleware.values.joined().forEach{
            
            $0(state, mutation, proxy.submit)
        }
        
        //---
        
        removeMiddlewareIfNeeded(mutation)
        
        //---
        
        // in one pass notify observers and release cancelled subscriptions
        subscriptions
            .filter { !$0.value.notifyAndKeep(with: state, mutation: mutation) }
            .map { $0.key }
            .forEach { subscriptions[$0] = nil }
    }
    
    //===
    
    func addMiddlewareIfNeeded(_ mutation: GlobalMutationExt)
    {
        let mutationType = type(of: mutation)
        let key = mutationType.feature.name
        
        if
            mutationType.kind == .addition
        {
            middleware[key] = mutationType.feature.middleware
        }
    }
    
    func removeMiddlewareIfNeeded(_ mutation: GlobalMutationExt)
    {
        let mutationType = type(of: mutation)
        let key = mutationType.feature.name
        
        if
            mutationType.kind == .removal
        {
            middleware[key] = nil
        }
    }
}
