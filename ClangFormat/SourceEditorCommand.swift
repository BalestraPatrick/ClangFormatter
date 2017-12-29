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

    static func run(_ commandPath: String, arguments: [String], stdin: String) -> String? {
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
                                                      arguments: [ "-style=llvm" ],
                                                      stdin: invocation.buffer.completeBuffer),
            invocation.buffer.contentUTI == "public.objective-c-source" {
            invocation.buffer.lines.removeAllObjects()

            let lines = outputString.split(separator: "\n").map { String($0) }
            invocation.buffer.lines.addObjects(from: lines)

            // Crashes Xcode when replacing `completeBuffer`
            //invocation.buffer.completeBuffer = outputString

            // If there is a no longer valid selection, Xcode crashes
            invocation.buffer.selections.removeAllObjects()
            // and it does the same if there aren't any selections, so we set the insertion point
            invocation.buffer.selections.add(XCSourceTextRange(start: XCSourceTextPosition(line: 0, column: 0),
                                                               end: XCSourceTextPosition(line: 0, column: 0)))
        }

        completionHandler(nil)
    }
}
