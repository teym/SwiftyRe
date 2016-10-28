
import UIKit

@testable import SwiftyRe

let str = "Hello, SwiftyRe. link: https://github.com/wl879/SwiftyRe"


Re("[,.:] +").split(str)

Re("[,.:] +").explode(str)

Re("https?:\\/\\/").test(str)

Re("\\W").match(str)?.values

Re("\\W", "g").match(str)?.values

Re("\\W", "g").replace(str, " ")

let re = Re("\\W")

while let m = re.exec(str) {
	m.values
}

// static method

Re.split(str, separator:" ")

Re.trim(str, pattern:"\\w+")

Re.slice(str, start: 23)
