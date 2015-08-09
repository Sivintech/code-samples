
import UIKit

// XMLResponseRepresentation represents the root element of an XML response
// (the root tag). As it adopts GenericXMLItem, MappedXMLItem and
// RootXMLItem, it's able to parse XML data, map XML values onto it's
// properties and pass the control of the XML parser down to its child
// objects representation.

class XMLResponseRepresentation : GenericXMLItem, MappedXMLItem, RootXMLItem
{
    var responseHash: Int
    {
        get
        {
            return _responseHash
        }
    }
    
    private var _responseHash: Int = 0
    var version: String?
    
    var childNodes: Array<GenericXMLItem> = Array<GenericXMLItem>()
    private var callback: ((responseRepresentation: XMLResponseRepresentation, error: NSError?) -> Void)?
    
    var error: ServerError?
    
    private var parser: NSXMLParser?
    private var dataToParse: NSData?
    
    override init()
    {
        super.init(attributes: nil)
    }
    
    // MARK: - RootXMLItem
    
    required convenience init(asRootElementWithXMLData XMLData: NSData, id: Int = 0)
    {
        self.init(attributes: nil)
        setUpForParsingData(XMLData)
        root = self
        _responseHash = id
    }
    
    required init(attributes: Dictionary<NSObject, AnyObject>!)
    {
        super.init(attributes: attributes)
    }
    
    func renderWithAdUnwrappingEndCallback(responseParsingEndCallBack: ((responseRepresentation: XMLResponseRepresentation, error: NSError?) -> Void)?) -> Void
    {
        callback = responseParsingEndCallBack
        if let value = value
        {
            if let wrappedResponseURL = NSURL(string: value)
            {
                visitURL(wrappedResponseURL, completionHandler: { [weak self] (success, data) -> Void in
                    if (success)
                    {
                        if (data.length > 0)
                        {
                            self?.setUpForParsingData(data)
                            self?.parser?.parse()
                        }
                    }
                    })
                
            }
        }
        
        var status = false
        if let parsingStatus = parser?.parse()
        {
            status = parsingStatus && (dataToParse?.length > 0)
        }
        
        if (status == false)
        {
            let error = NSError(domain: "XMLResponseRepresentation.NSXMLParser", code: 123, userInfo: ["Error description" : "The data to parse is empty"])
            callback?(responseRepresentation: self, error:error)
        }
    }
    
    
    // MARK: - MappedXMLItem
    
    override func classForTagNamed() -> () -> Dictionary<String, GenericXMLItem.Type>
    {
        let classMap: Dictionary<String, GenericXMLItem.Type> = ["ChildNode" : VASTchildNode.self,
            "Error" : ServerError.self]
        // Here's what is called the Module design pattern. It just mimics the static variable for classMap.
        func module() -> Dictionary<String, GenericXMLItem.Type>
        {
            return classMap
        }
        return module
    }
    
    override func keyPathForTagNamed() -> () -> Dictionary<String, String>
    {
        let keyPathMap: Dictionary<String, String> = ["ChildNode" : "childNodes",
            "Error" : "error"]
        
        // Here's what is called the Module design pattern.
        func module() -> Dictionary<String, String>
        {
            return keyPathMap
        }
        return module
    }
    
    override func actionForKeyPath() -> () -> Dictionary<String, KVCBinder>
    {
        let actionMap: Dictionary<String, KVCBinder> = ["childNodes" : inserter,
            "error" : assignor]
        
        func module() -> Dictionary<String, KVCBinder>
        {
            return actionMap
        }
        
        return module
    }
    
    // MARK: - internal (for future overriding)
    
    internal func setUpForParsingData(XMLData: NSData)
    {
        self.dataToParse = XMLData
        parser = NSXMLParser(data: XMLData) //as the standard SAX parser from UIKit doesn't allow reentrant parsing
        parser?.delegate = self
    }
    
    // MARK: - NSXMLParserDelegate
    
    override func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) -> Void
    {
        if let callback = callback
        {
            callback(responseRepresentation: self, error: parseError)
        }
    }
    
    override func parser(parser: NSXMLParser, validationErrorOccurred validationError: NSError)  -> Void
    {
        if let callback = callback
        {
            callback(responseRepresentation: self, error: validationError)
        }
    }
    
    override func parserDidEndDocument(parser: NSXMLParser) -> Void
    {
        let childNodes = self.childNodes
        if (childNodes.count > 0)
        {
            for childNode in childNodes
            {
                if let wrappedResponse = childNode.wrappedResponse
                {
                    if let type = childNode.type
                    {
                        if (type == XMLResponseType.Chained)
                        {
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {[unowned self]() -> Void in
                                wrappedResponse.renderWithAdUnwrappingEndCallback(self.callback)
                            }
                        }
                    }
                }
                else if let callback = self.callback
                {
                    callback(responseRepresentation: self, error: nil)
                    self.callback = nil
                }
            }
        }
        else
        {
            if let callback = self.callback
            {
                callback(responseRepresentation: self, error: nil)
                self.callback = nil
            }
        }
        
        parser.delegate = nil
    }
}