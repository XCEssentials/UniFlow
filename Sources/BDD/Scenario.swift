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

public
protocol ScenarioClause: CustomStringConvertible
{
    var prefix: String { get }
    var specification: String { get }
}

public
extension ScenarioClause
{
    var prefix: String
    {
        return "\(type(of: self))"
    }
    
    var description: String
    {
        return "\(prefix.uppercased()) \(specification)"
    }
}

// MARK: - Scenario

public
struct Scenario: CustomStringConvertible
{
    // MARK: - Public members
    
    public
    let story: Story.Type
    
    public
    let summary: String
    
    public
    var description: String
    {
        return "[\(story.name)] \(summary)"
    }
    
    public
    func onDidSatisfyWhen(_ handler: @escaping (Scenario) -> Void) -> Scenario
    {
        var result = self
        result.onDidSatisfyWhenHandler = handler
        
        //---
        
        return result
    }
    
    public
    func onDidSatisfyWhenDefault() -> Scenario
    {
        var result = self
        result.onDidSatisfyWhenHandler = { print($0.description) }
        
        //---
        
        return result
    }
    
    public
    func onWillPerformThen(_ handler: @escaping (Scenario) -> Void) -> Scenario
    {
        var result = self
        result.onWillPerformThenHandler = handler
        
        //---
        
        return result
    }
    
    public
    func onWillPerformThenDefault() -> Scenario
    {
        var result = self
        result.onWillPerformThenHandler = { print($0.description) }
        
        //---
        
        return result
    }
    
    // MARK: - Internal members
    
    var onDidSatisfyWhenHandler: ((Scenario) -> Void)?
    var onWillPerformThenHandler: ((Scenario) -> Void)?
    
    let when: When
    let given: [Given]
    let then: Then
    
    // MARK: - Initializers
    
    init(
        story: Story.Type,
        summary: String?,
        when: When,
        given: [Given],
        then: Then
        )
    {
        self.story = story
        
        self.when = when
        self.given = given
        self.then = then
        
        //===
        
        if
            let summary = summary
        {
            self.summary = summary
        }
        else
        {
            self.summary = type(of: self).constructSummary(when, given, then)
        }
    }
    
    // MARK: - Summary auto-constructor
    
    private
    static
    func constructSummary(
        _ when: ScenarioClause,
        _ given: [ScenarioClause],
        _ then: ScenarioClause
        ) -> String
    {
        return ([when] + given + [then])
            .map{ $0.description }
            .joined(separator: ", ") + "."
    }
}

// MARK: - Connector

public
extension Scenario
{
    struct Connector
    {
        let story: Story.Type
        let summary: String?
    }
}
