//
//  String.swift
//  KeYiNote
//
//  Created by Wang Liang on 2016/11/9.
//  Copyright © 2016年 wl. All rights reserved.
//

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

    public func slice(start: Int, end: Int? = nil, trim:CharacterSet? = nil) -> String{
        let len = self.characters.count
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
        return ref
    }
    
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
        res.append( self[ self.startIndex ..< r.lowerBound ] )
        res.append( self[ r.upperBound ..< self.endIndex  ] )
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
    
}
