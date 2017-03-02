//
//  Re.swift
//
//  Created by Wang Liang on 2016/10/28.
//  Copyright © 2016年 wl. All rights reserved.
//

import Foundation

public class Re {
	
	static private var cache = [String: NSRegularExpression]()
	
	public enum ExplodeOption {
		case keepSeparator
		case keepSeparatorBack
		case keepSeparatorFront
		case ignoreSeparator
	}
	
    public class Result:CustomStringConvertible  {
        public let values:[String]
        public let index:Int
        public let lastIndex: Int
        public let count:Int
		public subscript (key: Int) -> String? {
			if key < self.values.count{
				return self.values[key]
			}
			return nil
		}
        init(index: Int, lastIndex: Int, values:[String]) {
            self.index  = index
            self.lastIndex = lastIndex
            self.values = values
            self.count  = values.count
        }
        
        public var description: String {
            return "<Re.Result index: \(index), lastIndex: \(lastIndex), values: \(values)>"
        }
	}
	
	// MARK:
	
	let regex    : NSRegularExpression
	var flags    : Set<Character>
	var lastIndex: Int
	
	public init(_ pattern: String, _ flag:String = "") {
		
		self.lastIndex = 0
		self.flags     = Set(flag.characters)
	
		let id = pattern + "::::::" + self.flags.description
		
		if Re.cache[id] != nil {
			self.regex = Re.cache[id]!
		
		}else{
			var option:NSRegularExpression.Options = [.useUnixLineSeparators]
			for c in flag.characters {
				switch c {
				case "i":
					option.formUnion(.caseInsensitive)
				case "m":
					option.formUnion(.anchorsMatchLines)
				case "s":
					option.formUnion(.dotMatchesLineSeparators)
				case "g":
					break
				default:
					assertionFailure("[SwiftyRe] non-support flag:" + flag)
				}
			}
			self.regex = try! NSRegularExpression(pattern: pattern, options: option)
		}
	}
	
	public func test(_ input: String, offset:Int = 0) -> Bool {
		let len = input.characters.count
		if self.regex.firstMatch(in: input, range: NSMakeRange(offset, len - offset)) != nil {
			return true
		}
		return false
	}
	
	public func replace(_ input:String, _ template:String, offset:Int = 0) -> String{
		let len = input.characters.count
		return self.regex.stringByReplacingMatches(in : input, range : NSMakeRange(offset, len - offset), withTemplate : template)
	}
    
    public func replace(_ input:String, offset: Int = 0, _ template:@escaping (Re.Result) -> String ) -> String {
        var list = [String]()
        var offset = offset
        
        if offset > 0 {
            list.append( Re.slice(input, start: 0, end: offset) )
        }
        while let m = self.match(input, offset: offset, nonGlobal: true) {
            list.append( Re.slice(input, start: offset, end: m.index) )
            list.append( template(m) )
            offset = m.lastIndex+1
        }
        if offset < input.characters.count {
            list.append( Re.slice(input, start: offset) )
        }
        return list.joined()
    }
	
	public func match(_ input:String, offset:Int = 0, nonGlobal:Bool = false) -> Result?{
		let len = input.characters.count
		
		guard offset < len else {
			return nil
		}
		
		let range = NSMakeRange(offset, len - offset)
		
		if nonGlobal == false && self.flags.contains("g") {
			let matchs = self.regex.matches(in: input, range:range)
			if matchs.count > 0 {
				var res = [String]()
                var last = -1
				for m in matchs {
                    if m.range.length > 0 && m.range.location + m.range.length - 1 > last {
                        last = m.range.location + m.range.length - 1
                    }
					res.append( Re.slice(input, start: m.range.location, end: m.range.location + m.range.length) )
				}
				return Result(index: matchs[0].range.location, lastIndex: last, values: res)
			}

		}else{
			if let match = self.regex.firstMatch(in: input, range: range) {
				var res = [String]()
                var last = -1
				for i in 0 ..< match.numberOfRanges {
					let r = match.rangeAt(i)
                    if r.length > 0 && r.location + r.length - 1 > last {
                        last = r.location + r.length - 1
                    }
					res.append( Re.slice(input, start: r.location, end: r.location + r.length) )
				}
                return Result(index: match.range.location, lastIndex: last, values: res)
			}
		}
		return nil
	}
	
	public func exec(_ input:String) -> Result? {
		if let res = self.match(input, offset: self.lastIndex, nonGlobal: true) {
			self.lastIndex = res.index + res.values[0].characters.count
			return res
		}
		return nil
	}
	
	public func split(_ input:String, offset:Int = 0, trim:CharacterSet? = nil) -> [String]{
		return self.explode(input, offset: offset, trim: trim, option: .ignoreSeparator)
	}
	
    public func explode(_ input:String, offset:Int = 0, trim:CharacterSet? = nil, option:ExplodeOption = .keepSeparator) -> [String] {
		
		let len = input.characters.count
		let matchs = self.regex.matches(in: input, range: NSMakeRange(offset, len - offset))
		
		if matchs.count > 0 {

			var res   = [String]()
			var offset = 0
			
			for m in matchs {
				let r = m.range
				if offset != r.location {
                    
					res.append( Re.slice(input, start: offset, end: r.location, trim: trim) )
				}
				switch option {
				case .keepSeparator:
					res.append( Re.slice(input, start: r.location, end: r.location + r.length, trim: trim) )
					offset = r.location + r.length
					
				case .ignoreSeparator:
					offset = r.location + r.length
					
				case .keepSeparatorBack:
					if res.count > 0 {
						res[res.count - 1] += Re.slice(input, start: r.location, end: r.location + r.length, trim: trim)
					}else{
						res.append( Re.slice(input, start: r.location, end: r.location + r.length, trim: trim) )
					}
					offset = r.location + r.length
					
				case .keepSeparatorFront:
					offset = r.location
				}
			}
			if offset < len {
				res.append( Re.slice(input, start: offset, trim: trim) )
			}
			return res.filter({ $0.characters.count > 0 })
		}
		return [input]
	}
	
}

public extension Re {
    
    private static let symbol  = Re("([()\\[\\]?{}.*$^!\\+]|^\\|$)")
    private static let pair    = ["(":")", "[":"]", "{": "}", "\"":"\"", "\'": "\'"]
    private static let pairRe  = Re("(\\\\*)([()\"'{}\\[\\]])")
    
    public static func trim(_ string:String, pattern:String? = nil) -> String {
        if var pattern = pattern {
            pattern = symbol.replace(pattern, "\\\\$1")
            return Re("(" + pattern + ")+$").replace(Re("^(" + pattern + ")+").replace(string, ""), "")
        }
        return string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public static func lexer(code:String, separator: String, trim: CharacterSet? = nil) -> [String] {
        return lexer(code: code, separator: Re( symbol.replace(separator, "\\\\$1") ), trim: trim)
    }
    
    public static func lexer(code:String, separator sep: Re, trim: CharacterSet? = nil) -> [String] {
        var code = code
        
        var res    = [String]()
        var stack  = [String]()
        var bad    = false
        var offset = 0
        
        while !code.isEmpty && offset < code.characters.count {
            let sm = sep.match(code, offset: offset)
            if sm == nil && ( stack.isEmpty || bad ) {
                break
            }
            if bad == false {
                if let pm = pairRe.match(code, offset: offset) {
                    if !stack.isEmpty || pm.index < sm!.index {
                        offset = pm.lastIndex+1
                        if pm[1]!.isEmpty || pm[1]!.characters.count % 2 != 0 {
                            if stack.last == pm[2]! {
                                stack.removeLast()
                                continue
                            }
                            
                            if pair[ pm[2]! ] != nil {
                                stack.append( pair[ pm[2]! ]! )
                                continue
                            }
                            
                            if let index = stack.index(of: pm[2]!) {
                                while stack.count > index {
                                    stack.removeLast()
                                }
                                continue
                            }
                            
                            if !stack.isEmpty{
                                bad = true
                                offset = 0
                                continue
                            }
                            
                        }else {
                            continue
                        }
                    }
                }else if !stack.isEmpty {
                    if let pm = pairRe.match(code) {
                        stack.removeAll()
                        offset = pm.lastIndex+1
                        continue
                    }
                    break
                }
            }
            if sm == nil {
                break
            }
            res.append( Re.slice(code, start: 0, end: sm!.index, trim: trim) )
            code = Re.slice(code, start: sm!.lastIndex+1)
            offset = 0
        }
        if !code.isEmpty {
            if trim != nil {
                res.append( code.trimmingCharacters(in: trim!) )
            }else{
                res.append(code)
            }
        }
        return res.filter({ $0.characters.count > 0 })
    }
    
    public static func slice(_ str:String, start: Int, end: Int? = nil, trim:CharacterSet? = nil) -> String {
        let len = str.characters.count
        var start = start
        var end   = end == nil ? len : end!
        if start < 0 {
            start = len + start
        }
        if start > len {
            return ""
        }
        if end < 0 {
            end = len + end
        }
        if end > len - 1 {
            end = len
        }
        let start_index = str.index(str.startIndex, offsetBy: start)
        let end_index = str.index(str.startIndex, offsetBy: end)
        let ref = str[start_index ..< end_index]
        if trim != nil {
            return ref.trimmingCharacters(in: trim!)
        }
        return ref
    }
    
}


