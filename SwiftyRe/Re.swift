//
//  Re.swift
//
//  Created by Wang Liang on 2016/10/28.
//  Copyright © 2016年 wl. All rights reserved.
//

import Foundation

public class Re {
	
	static private var cache = [String: NSRegularExpression]()
	
	public enum ExplodeOption{
		case keepSeparator
		case keepSeparatorBack
		case keepSeparatorFront
		case ignoreSeparator
	}
	
	public struct Result {

		var values = [String]()
		var index  = 0
		
		subscript (key: Int) -> String? {
			if key < self.values.count{
				return self.values[key]
			}
			return nil
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
	
	public func match(_ input:String, offset:Int = 0, nonGlobal:Bool = false) -> Result?{
		let len = input.characters.count
		
		guard offset < len else {
			return nil
		}
		
		let range = NSMakeRange(offset, len - offset)
		
		if nonGlobal == false && self.flags.contains("g") {
			let matchs = self.regex.matches(in: input, range:range)
			if matchs.count > 0 {
				var res = Result()
				res.index = matchs[0].range.location
				for m in matchs {
					res.values.append( Re.slice(input, start:m.range.location, end:m.range.location + m.range.length ) )
				}
				return res
			}

		}else{
			if let match = self.regex.firstMatch(in: input, range: range) {
				var res = Result()
				res.index = match.range.location
				for i in 0 ..< match.numberOfRanges {
					let r = match.rangeAt(i)
					res.values.append( Re.slice(input, start:r.location, end:r.location + r.length ) )
				}
				return res
			}
		}
		return nil
	}
	
	public func exec(_ input:String) -> Result?{
		if let res = self.match(input, offset: self.lastIndex, nonGlobal: true) {
			self.lastIndex = res.index + res.values[0].characters.count
			return res
		}
		return nil
	}
	
	public func split(_ input:String, offset:Int = 0) -> [String]{
		return self.explode(input, offset: offset, option: .ignoreSeparator)
	}
	
	public func explode(_ input:String, offset:Int = 0, option:ExplodeOption = .keepSeparator) -> [String] {
		
		let len = input.characters.count
		let matchs = self.regex.matches(in: input, range: NSMakeRange(offset, len - offset))
		
		if matchs.count > 0 {

			var res   = [String]()
			var offset = 0
			
			for m in matchs {
				let r = m.range
				if offset != r.location {
					res.append( Re.slice(input, start: offset, end: r.location) )
				}
				switch option {
				case .keepSeparator:
					res.append( Re.slice(input, start: r.location, end: r.location + r.length) )
					offset = r.location + r.length
					
				case .ignoreSeparator:
					offset = r.location + r.length
					
				case .keepSeparatorBack:
					if res.count > 0 {
						res[res.count - 1] += Re.slice(input, start: r.location, end: r.location + r.length)
					}else{
						res.append( Re.slice(input, start: r.location, end: r.location + r.length) )
					}
					offset = r.location + r.length
					
				case .keepSeparatorFront:
					offset = r.location
				}
			}
			if offset < len {
				res.append( Re.slice(input, start: offset) )
			}
			return res
		}
		return [input]
	}
	
}

public extension Re {
	
	public class func trim(_ string:String, pattern:String? = nil) -> String {
		if let pattern = pattern {
			return Re("(" + pattern + ")+$").replace(Re("^(" + pattern + ")+").replace(string, ""), "")
		}
		return string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
		
	}
	
	public class func split(_ str: String, separator: String) -> [String]{
		
		return str.components(separatedBy: separator).filter({ $0.characters.count > 0 })
		
	}
	
	public class func slice(_ str:String, start: Int, end: Int? = nil) -> String{
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
		return str[start_index ..< end_index]
		
	}
	
}


