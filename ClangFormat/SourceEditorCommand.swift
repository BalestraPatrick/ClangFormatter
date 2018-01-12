//
//  SourceEditorCommand.swift
//  ClangFormat
//
//  Created by Boris Bügling on 21/06/16.
//  Copyright © 2016 🚀. All rights reserved.
//

import Foundation
import XcodeKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    let pl_file = FileSystem()
    
    var commandPath: String {
        return Bundle.main.path(forResource: "clang-format", ofType: nil)!
    }

    static func run(_ commandPath: String, arguments: [String], stdin: String) -> String? {
        
        print("Path : \(Bundle.main.bundlePath)")
        
        let errorPipe = Pipe()
        let outputPipe = Pipe()
 
        let task = Process()
        task.standardError = errorPipe
        task.standardOutput = outputPipe
        task.launchPath = commandPath
        task.arguments = arguments

        let inputPipe = Pipe()
        task.standardInput = inputPipe
        let stdinHandle = inputPipe.fileHandleForWriting

        if let data = stdin.data(using: .utf8) {
            stdinHandle.write(data)
            stdinHandle.closeFile()
        }

        task.launch()
        task.waitUntilExit()
        
        errorPipe.fileHandleForReading.readDataToEndOfFile()
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: outputData, encoding: .utf8)
    }

    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) {
        if let outputString = SourceEditorCommand.run(commandPath,
                                                      arguments: [ "-style=file", "-assume-filename=Objective-C" ],
                                                      stdin: invocation.buffer.completeBuffer),
            invocation.buffer.contentUTI == "public.objective-c-source" {
            
            // Maybe trigger Xcode Crash.
            invocation.buffer.completeBuffer = outputString
        }

        completionHandler(nil)
    }
    
    
}
