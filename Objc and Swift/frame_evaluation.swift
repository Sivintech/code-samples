//The dictionary (1st argument). The dictionary contains a frame definition that conforms to the rules below:
//Position:
//a) Center. When this is set, control is displayed in player’s center with specified width and height.
//b) Left+Width. When this mode is set, the target frame's horizontal position is specified by distance from the parent view's left border to the target frame's left border alongside its width.
//c) Right+Width. The target frame's horizontal position is defined by distance from the target frame's right border to the parent view's right border alongside its width.
//d) Left+Right. The target frame's horizontal position is defined by distance from target frame's left border to the parent view's left border alongside distance from the target frame's right border to the parent view's right border. The target frame's width in this case depends on the parent view's width.
//Same options are available for the target frame's vertical position and height.
//The parent view frame (2nd argument) is an instance of CGRect. It defines the frame the guiding view (a.k.a. the parent view).
//The return value is the target frame.

private func frameFromDictionary(dictionary: Dictionary<String, AnyObject>, onViewWithFrame parentViewFrame: CGRect) -> CGRect
{
    var origin: CGPoint = CGPointMake(0, 0)
    var size: CGSize = CGSizeMake(0, 0)
    
    //The closure for extracting a rectangle's dimensions as integets
    let primitiveResolvingClosure = { (standardizedRectangleAttribute: String, belongsAmongHorizontal: Bool) -> CGFloat? in
        var returnValue: CGFloat? = nil
        if var chainedOptional: AnyObject = dictionary[standardizedRectangleAttribute]
        {
            if let absolute = chainedOptional as? NSNumber
            {
                chainedOptional = CGFloat(absolute.integerValue) // ensuring no fractions
            }
            else if let dimensionString = chainedOptional as? String
            {
                if (dimensionString.hasSuffix("%")) // in case when a dimension is defined as a portion of the according parent view's dimension (e.g. 40%)
                {
                    let purePercentageString = dimensionString.stringByTrimmingCharactersInSet(NSCharacterSet.symbolCharacterSet())
                    let scanner = NSScanner(string: purePercentageString)
                    var percentageInt: Int = 0
                    if (scanner.scanInteger(&percentageInt))
                    {
                        var targetDimension: CGFloat?
                        if (belongsAmongHorizontal)
                        {
                            targetDimension = parentViewFrame.size.width
                        }
                        else
                        {
                            targetDimension = parentViewFrame.size.height
                        }
                        chainedOptional = CGFloat(percentageInt) *  targetDimension! / 100
                    }
                }
                else
                {
                    let scanner = NSScanner(string: dimensionString)
                    var absoluteInt: Int = 0
                    if (scanner.scanInteger(&absoluteInt))
                    {
                        chainedOptional = CGFloat(absoluteInt)
                    }
                }
            }
            
            returnValue = chainedOptional as? CGFloat
        }
        return returnValue
    }
    
    
    if let width = primitiveResolvingClosure("width", true)
    {
        size.width = width
    }
    
    if let height = primitiveResolvingClosure("height", false)
    {
        size.height = height
    }
    
    // Evaluating horizontal position and width
    if let x = primitiveResolvingClosure("left", true)
    {
        origin.x = x
        
        if let right = primitiveResolvingClosure("right", true) // the case of "left+right"
        {
            size.width = parentViewFrame.size.width - right - x
        }
    }
    else if let opposite = primitiveResolvingClosure("right", true) // the case of "right+width"
    {
        origin.x = parentViewFrame.size.width - size.width - opposite
    }
    else if let centeringModeOn = dictionary["center"] as? NSNumber // the case of "center+width"
    {
        if (centeringModeOn.boolValue)
        {
            origin.x = (parentViewFrame.size.width - size.width) / 2
        }
    }
    
    // Evaluating vertical position and height
    if let y = primitiveResolvingClosure("top", false)
    {
        origin.y = y
        
        if let bottom = primitiveResolvingClosure("bottom", false) // the case of "top+bottom"
        {
            size.height = parentViewFrame.size.height - bottom - y
        }
    }
    else if let opposite = primitiveResolvingClosure("bottom", true) // the case of "bottom+height"
    {
        origin.y = parentViewFrame.size.height - size.height - opposite
    }
    else if let centeringModeOn = dictionary["center"] as? NSNumber // the case of "center+height"
    {
        if (centeringModeOn.boolValue)
        {
            origin.y = (parentViewFrame.size.height - size.height) / 2
        }
    }
    
    return CGRect(origin: origin, size: size)
}