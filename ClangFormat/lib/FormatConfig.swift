//
//  FormatConfig.swift
//  ClangFormat
//
//  Created by LinJiang on 19/01/2018.
//  Copyright © 2018 🚀. All rights reserved.
//

import Foundation

class FormatConfig {
    var language : String
    var filename : String
    var filenameDefault : String
    
    init() {
        language = "Objective-C"
        filename = "_clang-format-objc"
        filenameDefault = ".clang-format"
        
    }
    
    
}
