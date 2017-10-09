//  Created by Wang Liang on 2017/4/8.
//  Copyright © 2017年 Wang Liang. All rights reserved.
import Foundation

extension String {
    
    public subscript(index: Int) -> String? {
        if index < self.characters.count {
            return String(self[self.index(self.startIndex, offsetBy: index)])
        }
        return nil
    }
    
    public subscript(start: Int, end: Int) -> String {
        return self.slice(start: start, end: end)
    }
    
    /// 拆分字符串，并修剪拆分后的字符串。例：
    ///
    ///     "a  b    c d".components(separatedBy: " ", trim: .whitespaces)
    ///     // return ["a", "b", "c", "d"]
    
    public func components(separatedBy separator: String, trim:CharacterSet) -> [String] {
        var res = self.components(separatedBy: separator)
        for i in (0 ..< res.count).reversed() {
            res[i] = res[i].trimmingCharacters(in: trim)
            if res[i].characters.isEmpty {
                res.remove(at: i)
            }
        }
        return res
    }
    
    public func components(separatedBy separator: String, atAfter: Int, trim:CharacterSet? = nil) -> [String]? {
        guard let r = self.range(of: separator, range: (self.index(self.startIndex, offsetBy: atAfter) ..< self.endIndex) ) else {
            return nil
        }
        var res = [String]()
        res.append( String(self[ self.startIndex ..< r.lowerBound ]) )
        res.append( String(self[ r.upperBound ..< self.endIndex  ]) )
        if trim != nil {
            for i in (0 ..< res.count).reversed() {
                res[i] = res[i].trimmingCharacters(in: trim!)
                if res[i].characters.isEmpty {
                    res.remove(at: i)
                }
            }
        }
        return res
    }
    
    /// 以 characters 的个数为引索截取字符串
    
    public func slice(start: Int, end: Int? = nil, trim:CharacterSet? = nil) -> String{
        let len   = self.characters.count
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
        let start_index = self.index(self.startIndex, offsetBy: start)
        let end_index = self.index(self.startIndex, offsetBy: end)
        let ref = self[start_index ..< end_index]
        if trim != nil {
            return ref.trimmingCharacters(in: trim!)
        }
        return String(ref)
    }
    
}

public class Re {
    
    private static var cache   = [String: NSRegularExpression]()
    
    public enum ExplodeOption {
        case keepSeparator
        case keepSeparatorBack
        case keepSeparatorFront
        case ignoreSeparator
    }
    
    // MARK: -
    
    public class Result: CustomStringConvertible {
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
    
    // MARK: -
    
    let regex    : NSRegularExpression
    
    var flags    : Set<Character>
    
    var lastIndex: Int
    
    /// 正则表达式
    
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
    
    public final func test(_ input: String, offset:Int = 0) -> Bool {
        guard let r = _toNSRange(offset: offset, with: input) else {
            return false
        }
        if self.regex.firstMatch(in: input, range: r) != nil {
            return true
        }
        return false
    }
    
    public final func replace(_ input:String, _ template:String, offset:Int = 0) -> String{
        guard let r = _toNSRange(offset: offset, with: input) else {
            return input
        }
        return self.regex.stringByReplacingMatches(in: input, range: r, withTemplate: template)
    }
    
    public final func replace(_ input:String, offset: Int = 0, _ template:@escaping (Re.Result) -> String ) -> String {
        var list = [String]()
        var offset = offset
        
        if offset > 0 {
            list.append(input[0, offset])
        }
        while let m = self.match(input, offset: offset, nonGlobal: true) {
            list.append( input[offset, m.index] )
            list.append( template(m) )
            offset = m.lastIndex+1
        }
        if offset < input.characters.count {
            list.append( input.slice(start: offset) )
        }
        return list.joined()
    }
    
    public final func match(_ input:String, offset:Int = 0, nonGlobal:Bool = false) -> Result?{
        guard let r = _toNSRange(offset: offset, with: input) else {
            return nil
        }
        if nonGlobal == false && self.flags.contains("g") {
            let matchs = self.regex.matches(in: input, range: r)
            if matchs.count > 0 {
                var res = [String]()
                var last = -1
                for m in matchs {
                    if m.range.length > 0 && m.range.location + m.range.length - 1 > last {
                        last = m.range.location + m.range.length - 1
                    }
                    res.append( _sliceByNSRange(input, m.range) )
                }
                return Result(index: _toCharsDistance(input, utf16: matchs[0].range.location)!, lastIndex: _toCharsDistance(input, utf16: last)!, values: res)
            }
            
        }else{
            if let match = self.regex.firstMatch(in: input, range: r) {
                var res = [String]()
                var last = -1
                for i in 0 ..< match.numberOfRanges {
                    let r = match.range(at: i)
                    if r.length > 0 && r.location + r.length - 1 > last {
                        last = r.location + r.length - 1
                    }
                    res.append( _sliceByNSRange(input, r) )
                }
                return Result(index: _toCharsDistance(input, utf16: match.range.location)!, lastIndex: _toCharsDistance(input, utf16: last)!, values: res)
            }
        }
        return nil
    }
    
    public final func exec(_ input:String) -> Result? {
        if let res = self.match(input, offset: self.lastIndex, nonGlobal: true) {
            self.lastIndex = res.lastIndex
            return res
        }
        self.lastIndex = 0
        return nil
    }
    
    public final func split(_ input:String, offset:Int = 0, trim:CharacterSet? = nil) -> [String]{
        return self.explode(input, offset: offset, trim: trim, option: .ignoreSeparator)
    }
    
    /// 拆分字符串，设置 option 可以保留拆分表达式匹配的结果。例:
    ///
    ///     Re("[,.!]").explode("a,b.c!", option: .keepSeparator)
    ///     // return ["a", ",", "b", ".", "c", "!"]
    ///
    ///     Re("[,.!]").explode("a,b.c!", option: .keepSeparatorBack)
    ///     // return ["a", ",b", ".c", "!"]
    ///
    ///     Re("[,.!]").explode("a,b.c!", option: .keepSeparatorFront)
    ///     // return ["a,", "b.", "c!"]
    ///
    ///     Re("[,.!]").explode("a,b.c!", option: .ignoreSeparator)
    ///     // return ["a", "b", "c"]
    
    public final func explode(_ input:String, offset:Int = 0, trim:CharacterSet? = nil, option:ExplodeOption = .keepSeparator) -> [String] {
        guard let r = _toNSRange(offset: offset, with: input) else {
            return [input]
        }
        let matchs = self.regex.matches(in: input, range: r)
        
        if matchs.count > 0 {
            
            let len = input.utf16.count
            var res = [String]()
            var i = 0
            
            for m in matchs {
                let r = m.range
                if i != r.location {
                    res.append( _sliceByNSRange(input, NSMakeRange(i, r.location-i), trim: trim)  )
                }
                switch option {
                case .keepSeparator:
                    res.append( _sliceByNSRange(input, r, trim: trim) )
                    i = r.location + r.length
                    
                case .ignoreSeparator:
                    i = r.location + r.length
                    
                case .keepSeparatorBack:
                    if res.count > 0 {
                        res[res.count - 1] += _sliceByNSRange(input, r, trim: trim)
                    }else{
                        res.append( _sliceByNSRange(input, r, trim: trim) )
                    }
                    i = r.location + r.length
                    
                case .keepSeparatorFront:
                    i = r.location
                }
            }
            if i < len {
                res.append( _sliceByNSRange(input, NSMakeRange(i, len-i), trim: trim) )
            }
            return res.filter({ $0.characters.count > 0 })
        }
        return [input]
    }
    
}


extension Re {
    
    public static func trim(_ string:String, pattern:String? = nil) -> String {
        if var pattern = pattern {
            pattern = symbol.replace(pattern, "\\\\$1")
            return Re("(" + pattern + ")+$").replace(Re("^(" + pattern + ")+").replace(string, ""), "")
        }
        return string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    
    /// 根据语法规则，拆分字符串，例:
    ///
    ///     Re.lexer(code: "a,(b, c),d", separator: ",")
    ///     // return ["a", "(b, c)", "d"]
    ///
    ///     Re.lexer(code: "a,\"b, c\",d", separator: ",")
    ///     // return ["a", "\"b, c\"", "d"]
    
    public static func lexer(code:String, separator: String, trim: CharacterSet? = nil, option:ExplodeOption = .ignoreSeparator, replace: String? = nil) -> [String] {
        return lexer(code: code, separator: Re( symbol.replace(separator, "\\\\$1") ), trim: trim, option: option, replace: replace)
    }
    
    public static func lexer(code:String, separator sep: Re, trim: CharacterSet? = nil, option:ExplodeOption = .ignoreSeparator, replace: String? = nil) -> [String] {
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
            
            res.append( code.slice(start: 0, end: sm!.index, trim: trim) )
            
            code = code.slice(start: sm!.lastIndex+1)
            offset = 0
            
            if option != .ignoreSeparator {
                let s = replace != nil ? replaceTemplate(replace!, result: sm!) : sm![0]!
                if option == .keepSeparator {
                    res.append( s )
                    
                }else if option == .keepSeparatorBack {
                    code = s + code
                    offset = s.characters.count
                    
                }else if option == .keepSeparatorFront {
                    res[res.count-1] += s
                }
            }
            
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
    
    private static func replaceTemplate(_ tmp: String, result: Result ) -> String {
        return tmpRe.replace(tmp, { r in
            if r[1] != nil, let i = Int(r[1]!) {
                return result[i] ?? ""
            }
            return r[0] ?? ""
        })
    }
    
}

private let symbol  = Re("([()\\[\\]?{}.*$^!\\+]|^\\|$)")

private let pair    = ["(":")", "[":"]", "{": "}", "\"":"\"", "\'": "\'"]

private let pairRe  = Re("(\\\\*)([()\"'{}\\[\\]])")

private let tmpRe  = Re("(?<!\\\\)\\$(\\d+)")


private func _sliceByNSRange(_ str: String, _ range: NSRange, trim:CharacterSet? = nil) -> String {
    guard let range = _toIndexRange(str, with: range) else {
        return ""
    }
    if trim != nil {
        return str[range].trimmingCharacters(in: trim!)
    }
    return String(str[range])
}

private func _toIndex(_ str: String, utf16: Int) -> String.Index? {
    if let u = str.utf16.index(str.utf16.startIndex, offsetBy: utf16, limitedBy: str.utf16.endIndex) {
        return String.Index(u, within: str)
    }
    return nil
}

private func _toIndexRange(_ str: String, with range: NSRange) -> Range<String.Index>? {
    guard range.location != NSNotFound else {
        return nil
    }
    return _toIndexRange(str, location: range.location, length: range.length)
}

private func _toIndexRange(_ str: String, location: Int, length:Int) -> Range<String.Index>? {
    if length <= 0 {
        return nil
    }
    if let start = _toIndex(str, utf16: location), let end = _toIndex(str, utf16: location + length) {
        return start ..< end
    }
    return nil
}

private func _toNSRange(_ str: String, start: Int, length: Int) -> NSRange? {
    if length <= 0 {
        return nil
    }
    if let location = _utf16Distance(str, distance: start), let end = _utf16Distance(str, distance: start+length) {
        return NSMakeRange(location, end - location)
    }
    return nil
}

private func _toNSRange(offset: Int, with str: String) -> NSRange? {
    let end = str.utf16.count
    if offset > 0 {
        if let start = _utf16Distance(str, distance: offset) {
            if start < end {
                return NSMakeRange(start, end - start)
            }
        }
        return nil
    }
    return NSMakeRange(0, end)
}

private func _utf16Distance(_ str: String, distance: Int) -> Int? {
    if let i = str.index(str.startIndex, offsetBy: distance, limitedBy: str.endIndex) {
        if let u = i.samePosition(in: str.utf16){
            return str.utf16.distance(from: str.utf16.startIndex, to: u)
        }
    }
    return nil
}

private func _toCharsDistance(_ str: String, utf16: Int) -> Int? {
    if let i = _toIndex(str, utf16: utf16) {
        return str.distance(from: str.startIndex, to: i)
    }
    return nil
}


