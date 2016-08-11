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
    var commandPath: String {
        return Bundle.main.path(forResource: "clang-format", ofType: nil)!
    }
    
      func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: (Error?) -> Void) {
        let errorPipe = Pipe()
        let outputPipe = Pipe()

        let task = Task()
        task.standardError = errorPipe
        task.standardOutput = outputPipe
        task.launchPath = commandPath
        task.arguments = [ "-style=llvm" ]

        print("Using clang-format \(task.launchPath)")

        let inputPipe = Pipe()
        task.standardInput = inputPipe
        let stdinHandle = inputPipe.fileHandleForWriting

        if let data = invocation.buffer.completeBuffer.data(using: .utf8) {
            stdinHandle.write(data)
            stdinHandle.closeFile()
        }

        task.launch()
        task.waitUntilExit()

        errorPipe.fileHandleForReading.readDataToEndOfFile()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        if let outputString = String(data: outputData, encoding: .utf8) {
            let lines = outputString.characters.split(separator: "\n").map { String($0) }
            invocation.buffer.lines.removeAllObjects()
            invocation.buffer.lines.addObjects(from: lines)

            //invocation.buffer.lines.removeAllObjects()
            //invocation.buffer.selections.removeAllObjects()
            //invocation.buffer.completeBuffer = outputString
            // Crashes Xcode when replacing `completeBuffer`
        }

        completionHandler(nil)
    }
}
