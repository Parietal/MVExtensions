//
//  MVExtensions.swift
//  MVExtensions
//
//  Created by Michael on 21/6/14.
//  Copyright (c) 2014 Michael Vu. All rights reserved.
//

import Foundation
import Swift

operator infix =~ {}
operator infix |~ {}

class MVExtensions {
    class func after <P, T> (n: Int, call: (P...) -> T) -> ((P...) -> T?) {
        var times = n
        return {(params: (P...)) -> T? in
            if times-- <= 0 {
                return call(reinterpretCast(params))
            }
            return nil
        }
    }
    class func after <T> (n: Int, call: Void -> T) -> (Void -> T?) {
        let f = after(n, call: {(params: (Any?...)) -> T? in
            return call()
        })
        return {
            return f(nil)?
        }
    }
    class func once <P, T> (call: (P...) -> T) -> ((P...) -> T?) {
        var executed = false
        return {(params: (P...)) -> T? in
            if (executed) {
                return nil
            }
            executed = true
            return call(reinterpretCast(params))
        }
    }
    class func once <T> (call: Void -> T) -> (Void -> T?) {
        let f = once {(params: Any?...) -> T? in
            return call()
        }
        return {
            return f(nil)?
        }
    }
    class func partial <P, T> (function: (P...) -> T, _ parameters: P...) -> ((P...) -> T) {
        return {(params: P...) -> T in
            return function(reinterpretCast(parameters + params))
        }
    }
    class func bind <P, T> (function: (P...) -> T, _ parameters: P...) -> (Void -> T) {
        return {Void -> T in
            return function(reinterpretCast(parameters))
        }
    }
    class func regex (pattern: String, ignoreCase: Bool = false) -> NSRegularExpression? {
        var options: NSRegularExpressionOptions = NSRegularExpressionOptions.DotMatchesLineSeparators
        if ignoreCase {
            options = NSRegularExpressionOptions.CaseInsensitive | options
        }
        var error: NSError? = nil
        let regex = NSRegularExpression.regularExpressionWithPattern(pattern, options: options, error: &error)
        return (error == nil) ? regex : nil
    }
}

extension Array {
    func contains <T: Equatable> (items: T...) -> Bool {
        return items.all { self.indexOf($0) >= 0 }
    }
    func difference <T: Equatable> (values: Array<T>...) -> Array<T> {
        var result = Array<T>()
        elements: for e in self {
            if let element = e as? T {
                for value in values {
                    if value.contains(element) {
                        continue elements
                    }
                }
                result.append(element)
            }
        }
        return result
    }
    func intersection <U: Equatable> (values: Array<U>...) -> Array {
        var result = self
        var intersection = Array()
        for (i, value) in enumerate(values) {
            if (i > 0) {
                result = intersection
                intersection = Array()
            }
            value.each { (item: U) -> Void in
                if result.contains(item) {
                    intersection.append(item as Element)
                }
            }
        }
        return intersection
    }
    func union <U: Equatable> (values: Array<U>...) -> Array {
        var result = self
        for array in values {
            for value in array {
                if !result.contains(value) {
                    result.append(value as Element)
                }
            }
        }
        return result
    }
    func first () -> Element? {
        if count > 0 {
            return self[0]
        }
        return nil
    }
    func last () -> Element? {
        if count > 0 {
            return self[count - 1]
        }
        return nil
    }
    func indexOf <U: Equatable> (item: U) -> Int? {
        if item is Element {
            if let found = find(reinterpretCast(self) as Array<U>, item) {
                return found
            }
            return nil
        }
        return nil
    }
    func lastIndexOf <U: Equatable> (item: U) -> Int? {
        if item is Element {
            if let index = reverse().indexOf(item) {
                return count - index - 1
            }
            return nil
        }
        return nil
    }
    func get (index: Int) -> Element? {
        func relativeIndex (index: Int) -> Int {
            var _index = (index % count)
            if _index < 0 {
                _index = count + _index
            }
            return _index
        }
        var _index = relativeIndex(index)
        return _index < count ? self[_index] : nil
    }
    func get (range: Range<Int>) -> Array {
        return self[range]
    }
    func zip (arrays: Array<Any>...) -> Array<Array<Any?>> {
        var result = Array<Array<Any?>>()
        let max = arrays.map { (array: Array<Any>) -> Int in
            return array.count
            }.max() as Int
        for i in 0..max {
            result.append([get(i)] + arrays.map {
                (array: Array<Any>) -> Any? in return array.get(i)
                })
        }
        return result
    }
    func partition (var n: Int, var step: Int? = nil) -> Array<Array<Element>> {
        var result = Array<Array<Element>>()
        if !step?   { step = n }
        if step < 1 { step = 1 }
        if n < 1    { n = 0 }
        if n > count { return [[]] }
        for i in (0...count-n).by(step!) {
            result += self[i..(i+n)]
        }
        return result
    }
    func partition (var n: Int, var step: Int? = nil, pad: Element[]?) -> Array<Array<Element>> {
        var result = Array<Array<Element>>()
        if !step?   { step = n }
        if step < 1 { step = 1 }
        if n < 1    { n = 0 }
        for i in (0..count).by(step!) {
            var end = i+n
            if end > count { end = count }
            result += self[i..end]
            if end != i+n { break }
        }
        if let padding = pad {
            let remaining = count % n
            result[result.count-1] += padding[0..remaining] as Element[]
        }
        return result
    }
    func partitionAll (var n: Int, var step: Int? = nil) -> Array<Array<Element>> {
        var result = Array<Array<Element>>()
        if !step?   { step = n }
        if step < 1 { step = 1 }
        if n < 1    { n = 0 }
        for i in (0..count).by(step!) {
            result += self[i..i+n]
        }
        return result
    }
    func partitionBy <T: Equatable> (cond: (Element) -> T) -> Array<Array<Element>> {
        var result = Array<Array<Element>>()
        var lastValue: T? = nil
        for item in self {
            let value = cond(item)
            if value == lastValue? {
                result[result.count-1] += item
            } else {
                result.append([item])
                lastValue = value
            }
        }
        return result
    }
    mutating func shuffle () {
        for var i = self.count - 1; i >= 1; i-- {
            let j = Int.random(max: i)
            swap(&self[i], &self[j])
        }
    }
    func shuffled () -> Array {
        var shuffled = self
        for i in 0..self.count {
            let j = Int.random(max: i)
            if j != i {
                shuffled[i] = shuffled[j]
            }
            shuffled[j] = self[i]
        }
        return shuffled
    }
    func sample (size n: Int = 1) -> Array {
        if n >= count {
            return self
        }
        let index = Int.random(max: count - n)
        return self[index..(n + index)]
    }
    func max <U: Comparable> () -> U {
        return maxElement(map {
            return $0 as U
        })
    }
    func min <U: Comparable> () -> U {
        return minElement(map {
            return $0 as U
        })
    }
    func each (call: (Element) -> ()) {
        for item in self {
            call(item)
        }
    }
    func each (call: (Int, Element) -> ()) {
        for (index, item) in enumerate(self) {
            call(index, item)
        }
    }
    func eachRight (call: (Element) -> ()) {
        self.reverse().each(call)
    }
    func eachRight (call: (Int, Element) -> ()) {
        for (index, item) in enumerate(self.reverse()) {
            call(count - index - 1, item)
        }
    }
    func any (call: (Element) -> Bool) -> Bool {
        for item in self {
            if call(item) {
                return true
            }
        }
        return false
    }
    func all (call: (Element) -> Bool) -> Bool {
        for item in self {
            if !call(item) {
                return false
            }
        }
        return true
    }
    func reject (exclude: (Element -> Bool)) -> Array {
        return filter {
            return !exclude($0)
        }
    }
    func take (n: Int) -> Array {
        return self[0..n]
    }
    func takeWhile (condition: (Element) -> Bool) -> Array {
        var lastTrue = -1
        for (index, value) in enumerate(self) {
            if condition(value) {
                lastTrue = index
            } else {
                break
            }
        }
        return self.take(lastTrue+1)
    }
    func tail (n: Int) -> Array {
        return self[(count - n)..count]
    }
    func skip (n: Int) -> Array {
        return self[n..count]
    }
    func skipWhile (condition: (Element) -> Bool) -> Array {
        var lastTrue = -1
        for (index, value) in enumerate(self) {
            if condition(value) {
                lastTrue = index
            } else {
                break
            }
        }
        return self.skip(lastTrue+1)
    }
    func unique <T: Equatable> () -> Array<T> {
        var result = Array<T>()
        for item in self {
            if !result.contains(item as T) {
                result.append(item as T)
            }
        }
        return result
    }
    func groupBy <U> (groupingFunction group: (Element) -> U) -> Dictionary<U, Array> {
        var result = Dictionary<U, Element[]>()
        for item in self {
            let groupKey = group(item)
            if let elem = result[groupKey] {
                result[groupKey] = elem + [item]
            } else {
                result[groupKey] = [item]
            }
        }
        return result
    }
    func countBy <U> (groupingFunction group: (Element) -> U) -> Dictionary<U, Int> {
        var result = Dictionary<U, Int>()
        for item in self {
            let groupKey = group(item)
            if let elem = result[groupKey] {
                result[groupKey] = elem + 1
            } else {
                result[groupKey] = 1
            }
        }
        return result
    }
    func implode <C: ExtensibleCollection> (separator: C) -> C? {
        if Element.self is C.Type {
            return Swift.join(separator, reinterpretCast(self) as Array<C>)
        }
        return nil
    }
    func reduce (combine: (Element, Element) -> Element) -> Element {
        return skip(1).reduce(first()!, combine: combine)
    }
    func reduceRight <U> (initial: U, combine: (U, Element) -> U) -> U {
        return reverse().reduce(initial, combine: combine)
    }
    func reduceRight (combine: (Element, Element) -> Element) -> Element {
        return reverse().reduce(combine)
    }
    func at (indexes: Int...) -> Array {
        return indexes.map { self.get($0)! }
    }
    func flatten <OutType> () -> OutType[] {
        var result = OutType[]()
        for item in self {
            if item is OutType {
                result.append(item as OutType)
            } else if let bridged = bridgeFromObjectiveC(reinterpretCast(item), OutType.self) {
                result.append(bridged)
            } else if item is NSArray {
                result += (item as NSArray).flatten() as OutType[]
            }
        }
        return result
    }
    mutating func pop () -> Element {
        return self.removeLast()
    }
    mutating func push (newElement: Element) {
        return self.append(newElement)
    }
    mutating func shift () -> Element {
        return self.removeAtIndex(0)
    }
    mutating func unshift (newElement: Element) {
        self.insert(newElement, atIndex: 0)
    }
    mutating func remove <U: Equatable> (element: U) {
        let anotherSelf = self.copy()
        removeAll(keepCapacity: true)
        anotherSelf.each {(index: Int, current: Element) in
            if current as U != element {
                self.append(current)
            }
        }
    }
    static func range <U: ForwardIndex> (range: Range<U>) -> Array<U> {
        return Array<U>(range)
    }
    subscript (var range: Range<Int>) -> Array {
        (range.startIndex, range.endIndex) = (range.startIndex.clamp(0, max: range.startIndex), range.endIndex.clamp(range.endIndex, max: count))
        return Array(self[range] as Slice<T>)
    }
    subscript (first: Int, second:Int, rest: Int...) -> Array {
        return at(reinterpretCast([first, second] + rest))
    }
}

extension Dictionary {
    func difference <V: Equatable> (dictionaries: Dictionary<KeyType, V>...) -> Dictionary<KeyType, V> {
        var result = Dictionary<KeyType, V>()
        each {
            if let item = $1 as? V {
                result[$0] = item
            }
        }
        for dictionary in dictionaries {
            for (key, value) in dictionary {
                if result.has(key) && result[key] == value {
                    result.removeValueForKey(key)
                }
            }
        }
        return result
    }
    func union (dictionaries: Dictionary<KeyType, ValueType>...) -> Dictionary<KeyType, ValueType> {
        var result = self
        dictionaries.each { (dictionary) -> Void in
            dictionary.each { (key, value) -> Void in
                result.updateValue(value, forKey: key)
                return
            }
        }
        return result
    }
    func intersection <K, V where K: Equatable, V: Equatable> (dictionaries: Dictionary<K, V>...) -> Dictionary<K, V> {
        let filtered = self.filter({(item: KeyType, value: ValueType) -> Bool in
            return (item is K) && (value is V)
            }).map({ (item: KeyType, value: ValueType) -> (K, V) in
                return (item as K, value as V)
            })
        return filtered.filter({(item: K, value: V) -> Bool in
            dictionaries.all { $0.has(item) && $0[item] == value }
        })
    }
    func has (key: KeyType) -> Bool {
        return indexForKey(key) != nil
    }
    func mapValues <V> (mapFunction map: (KeyType, ValueType) -> (V)) -> Dictionary<KeyType, V> {
        var mapped = Dictionary<KeyType, V>()
        self.each({
            mapped[$0] = map($0, $1)
        })
        return mapped
    }
    func map <K, V> (mapFunction map: (KeyType, ValueType) -> (K, V)) -> Dictionary<K, V> {
        var mapped = Dictionary<K, V>()
        self.each({
            let (_key, _value) = map($0, $1)
            mapped[_key] = _value
        })
        return mapped
    }
    func each (eachFunction each: (KeyType, ValueType) -> ()) {
        for (key, value) in self {
            each(key, value)
        }
    }
    func filter (testFunction test: (KeyType, ValueType) -> Bool) -> Dictionary<KeyType, ValueType> {
        var result = Dictionary<KeyType, ValueType>()
        for (key, value) in self {
            if test(key, value) {
                result[key] = value
            }
        }
        return result
    }
    func isEmpty () -> Bool {
        return Array(self.keys).isEmpty
    }
    func groupBy <T> (groupingFunction group: (KeyType, ValueType) -> T) -> Dictionary<T, Array<ValueType>> {
        var result = Dictionary<T, ValueType[]>()
        for (key, value) in self {
            let groupKey = group(key, value)
            if let elem = result[groupKey] {
                result[groupKey] = elem + [value]
            } else {
                result[groupKey] = [value]
            }
        }
        return result
    }
    func countBy <T> (groupingFunction group: (KeyType, ValueType) -> (T)) -> Dictionary<T, Int> {
        var result = Dictionary<T, Int>()
        for (key, value) in self {
            let groupKey = group(key, value)
            if let elem = result[groupKey] {
                result[groupKey] = elem + 1
            } else {
                result[groupKey] = 1
            }
        }
        return result
    }
    func all (test: (KeyType, ValueType) -> (Bool)) -> Bool {
        for (key, value) in self {
            if !test(key, value) {
                return false
            }
        }
        return true
    }
    func any (test: (KeyType, ValueType) -> (Bool)) -> Bool {
        for (key, value) in self {
            if test(key, value) {
                return true
            }
        }
        return false
    }
    func reduce <U> (initial: U, combine: (U, Element) -> U) -> U {
        return Swift.reduce(self, initial, combine)
    }
    func pick (keys: KeyType[]) -> Dictionary {
        return filter { (key: KeyType, _) -> Bool in
            return keys.contains(key)
        }
    }
    func pick (keys: KeyType...) -> Dictionary {
        return pick(reinterpretCast(keys) as KeyType[])
    }
    func at (indexes: KeyType...) -> Dictionary {
        return pick(indexes)
    }
    mutating func shift () -> (KeyType, ValueType) {
        let key: KeyType! = Array(keys).first()
        let value: ValueType! = removeValueForKey(key)
        return (key, value)
    }
}

extension Float {
    func abs () -> Float {
        return fabsf(self)
    }
    func sqrt () -> Float {
        return sqrtf(self)
    }
    func digits () -> (integerPart: Int[], fractionalPart: Int[]) {
        var first: Int[]? = nil
        var current = Int[]()
        for char in String(self) {
            let string = String(char)
            if let toInt = string.toInt() {
                current.append(toInt)
            } else if string == "." {
                first = current
                current.removeAll(keepCapacity: true)
            }
        }
        if let integer = first {
            return (integer, current)
        }
        return (current, [0])
    }
    static func random(min: Float = 0, max: Float) -> Float {
        let diff = max - min;
        let rand = Float(arc4random() % (RAND_MAX.asUnsigned() + 1))
        return ((rand / Float(RAND_MAX)) * diff) + min;
    }
}

extension Int {
    func times <T> (call: () -> T) {
        self.times({(index: Int) -> T in
            return call()
        })
    }
    func times (call: () -> ()) {
        self.times({(index: Int) -> () in
            call()
        })
    }
    func times <T> (call: (Int) -> T) {
        (0..self).each { index in call(index); return }
    }
    func isEven () -> Bool {
        return (self % 2) == 0
    }
    func isOdd () -> Bool {
        return !self.isEven()
    }
    func upTo (limit: Int, call: (Int) -> ()) {
        if limit < self {
            return
        }
        (self...limit).each(call)
    }
    func downTo (limit: Int, call: (Int) -> ()) {
        if limit > self {
            return
        }
        Array(limit...self).reverse().each(call)
    }
    func clamp (range: Range<Int>) -> Int {
        if self > range.endIndex - 1 {
            return range.endIndex - 1
        } else if self < range.startIndex {
            return range.startIndex
        }
        return self
    }
    func clamp (min: Int, max: Int) -> Int {
        return clamp(min...max)
    }
    func isIn (range: Range<Int>, strict: Bool = false) -> Bool {
        if strict {
            return range.startIndex < self && self < range.endIndex - 1
        }
        return range.startIndex <= self && self <= range.endIndex - 1
    }
    func digits () -> Array<Int> {
        var result = Int[]()
        for char in String(self) {
            let string = String(char)
            if let toInt = string.toInt() {
                result.append(toInt)
            }
        }
        return result
    }
    func abs () -> Int {
        return Swift.abs(self)
    }
    func gcd (n: Int) -> Int {
        return n == 0 ? self : n.gcd(self % n)
    }
    func lcm (n: Int) -> Int {
        return (self * n).abs() / gcd(n)
    }
    static func random(min: Int = 0, max: Int) -> Int {
        return Int(arc4random_uniform(UInt32((max - min) + 1))) + min
    }
}

extension Range {
    func times (call: () -> ()) {
        each { (current: T) -> () in
            call()
        }
    }
    func times (call: (T) -> ()) {
        each (call)
    }
    func each (call: (T) -> ()) {
        for i in self {
            call(i)
        }
    }
    static func random (from: Int, to: Int) -> Range<Int> {
        let lowerBound = Int.random(min: from, max: to)
        let upperBound = Int.random(min: lowerBound, max: to)
        return lowerBound...upperBound
    }
}

extension String {
    var length: Int {
        return countElements(self)
    }
    subscript (range: Range<Int>) -> String? {
        return Array(self).get(range).reduce(String(), +)
    }
    subscript (indexes: Int...) -> String[] {
        return at(reinterpretCast(indexes))
    }
    subscript (index: Int) -> String? {
        if let char = Array(self).get(index) {
            return String(char)
        }
        return nil
    }
    func at (indexes: Int...) -> String[] {
        return indexes.map { self[$0]! }
    }
    func explode (separator: Character) -> String[] {
        return split(self, {(element: Character) -> Bool in
            return element == separator
        })
    }
    func matches (pattern: String, ignoreCase: Bool = false) -> NSTextCheckingResult[]? {
        if let regex = MVExtensions.regex(pattern, ignoreCase: ignoreCase) {
            return regex.matchesInString(self, options: nil, range: NSMakeRange(0, length)) as? NSTextCheckingResult[]
        }
        return nil
    }
    func capitalized () -> String {
        return capitalizedString
    }
    func insert (index: Int, _ string: String) -> String {
        return self[0..index]! + string + self[index..length]!
    }
    func ltrimmed () -> String {
        let range = rangeOfCharacterFromSet(NSCharacterSet.whitespaceAndNewlineCharacterSet().invertedSet)
        return self[range.startIndex..endIndex]
    }
    func rtrimmed () -> String {
        let range = rangeOfCharacterFromSet(NSCharacterSet.whitespaceAndNewlineCharacterSet().invertedSet, options: NSStringCompareOptions.BackwardsSearch)
        return self[startIndex..range.endIndex]
    }
    func trimmed () -> String {
        return ltrimmed().rtrimmed()
    }
    static func random (var length len: Int = 0, charset: String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") -> String {
        if len < 1 {
            len = Int.random(max: 16)
        }
        var result = String()
        let max = charset.length - 1
        len.times {
            result += charset[Int.random(min: 0, max: max)]!
        }
        return result
    }
    func repeat(times: Int, _ separator:String? = "") -> String {
        var result = ""
        for i in 0..times {
            result += separator! + self
        }
        if separator!.isEmpty == false {
            return result.substringFromIndex(countElements(separator!))
        }
        return result
    }
}

extension NSArray {
    func cast <OutType> () -> OutType[] {
        var result = OutType[]()
        for item : AnyObject in self {
            if let converted = bridgeFromObjectiveC(item, OutType.self) {
                result.append(converted)
            }
        }
        return result
    }
    func flatten <OutType> () -> OutType[] {
        var result = OutType[]()
        for item: AnyObject in self {
            if let converted = bridgeFromObjectiveC(item, OutType.self) {
                result.append(converted)
            } else if item is NSArray {
                result += (item as NSArray).flatten() as OutType[]
            }
        }
        return result
    }
}

//Infix func for Array
@infix func - <T: Equatable> (first: Array<T>, second: T) -> Array<T> {
    return first - [second]
}
@infix func - <T: Equatable> (first: Array<T>, second: Array<T>) -> Array<T> {
    return first.difference(second)
}
@infix func & <T: Equatable> (first: Array<T>, second: Array<T>) -> Array<T> {
    return first.intersection(second)
}
@infix func | <T: Equatable> (first: Array<T>, second: Array<T>) -> Array<T> {
    return first.union(second)
}
@infix func * <ItemType> (array: ItemType[], n: Int) -> ItemType[] {
    var result = ItemType[]()
    n.times {
        result += array
    }
    return result
}
@infix func * (array: String[], separator: String) -> String {
    return array.implode(separator)!
}
//Infix func for Dictionary
@infix func + <K, V: Equatable>(first: Dictionary<K, V>, second: Dictionary<K, V>) -> Dictionary<K,V>
{
    return first.union(second)
}
@infix func - <K, V: Equatable> (first: Dictionary<K, V>, second: Dictionary<K, V>) -> Dictionary<K, V> {
    return first.difference(second)
}
@infix func & <K, V: Equatable> (first: Dictionary<K, V>, second: Dictionary<K, V>) -> Dictionary<K, V> {
    return first.intersection(second)
}
@infix func | <K, V: Equatable> (first: Dictionary<K, V>, second: Dictionary<K, V>) -> Dictionary<K, V> {
    return first.union(second)
}
//Infix func for Range
@infix func == <U: ForwardIndex> (first: Range<U>, second: Range<U>) -> Bool {
    return first.startIndex == second.startIndex &&
        first.endIndex == second.endIndex
}
@infix func * (first: String, n: Int) -> String {
    var result = String()
    n.times {
        result += first
    }
    return result
}
//Infix func for String
@infix func =~ (string: String, pattern: String) -> Bool {
    return string =~ (pattern: pattern, ignoreCase: false)
}
@infix func =~ (string: String, options: (pattern: String, ignoreCase: Bool)) -> Bool {
    if let matches = MVExtensions.regex(options.pattern, ignoreCase: options.ignoreCase)?.numberOfMatchesInString(string, options: nil, range: NSMakeRange(0, string.length)) {
        return matches > 0
    }
    return false
}
@infix func =~ (strings: String[], pattern: String) -> Bool {
    return strings.all { $0 =~ (pattern: pattern, ignoreCase: false) }
}
@infix func =~ (strings: String[], options: (pattern: String, ignoreCase: Bool)) -> Bool {
    return strings.all { $0 =~ options }
}
@infix func |~ (strings: String[], pattern: String) -> Bool {
    return strings.any { $0 =~ (pattern: pattern, ignoreCase: false) }
}
@infix func |~ (strings: String[], options: (pattern: String, ignoreCase: Bool)) -> Bool {
    return strings.any { $0 =~ options }
}