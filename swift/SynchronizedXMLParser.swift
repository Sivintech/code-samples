//
//  SynchronizedXMLParser.swift
//  XMLParserDemo
//
//  Created by Arthur Gevorkyan on 10.09.15.
//  No license here - just common sense :)
//

import UIKit

class SynchronizedXMLParser: NSXMLParser
{
    // shared queue
    private static var _serialQueue: NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.qualityOfService = NSQualityOfService.UserInitiated
        // making it serial on purpose in order to avoid 
        // the "reentrant parsing" issue
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    // instance level convenience accessor
    private var _serialQueue: NSOperationQueue
    {
        get
        {
            return self.dynamicType._serialQueue
        }
    }
    
    private weak var _associatedParsingTask: NSBlockOperation?
    
//MARK: - Overridden
    
    required override init(data: NSData)
    {
        super.init(data: data)
    }
    
    override func parse() -> Bool
    {
        var parsingResult = false
        
        if (_associatedParsingTask == nil)
        {
            let parsingTask = NSBlockOperation(block: {() -> Void in
                parsingResult = super.parse()
            })
            _associatedParsingTask = parsingTask
            // making it synchronous in order to return the result 
            // of the super's parse call
            _serialQueue.addOperations([parsingTask], waitUntilFinished: true)
        }
        
        return parsingResult
    }
    
    override func abortParsing()
    {
        if let parsingTask = _associatedParsingTask
        {
            parsingTask.cancel()
            _associatedParsingTask = nil
        }
        
        super.abortParsing()
    }
    
    deinit
    {
        _associatedParsingTask?.cancel()
    }
    
}
