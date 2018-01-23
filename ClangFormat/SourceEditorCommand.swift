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

    // max bytes of config file.  default: 100 KB.
    static let plkConfigMaxSizeBytes = 100 * 1024

    let plConfig = FormatConfig()


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

        if !SourceEditorCommand.updateConfigIfNeeded(currentDirectory: task.currentDirectoryPath) {
            return nil
        }

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
                                                      arguments: ["-style=file", "-assume-filename=\(plConfig.language)"],
                                                      stdin: invocation.buffer.completeBuffer),
            invocation.buffer.contentUTI == "public.objective-c-source" {

            invocation.buffer.completeBuffer = outputString
        }

        completionHandler(nil)
    }

    // MARK: -
    static func updateConfigIfNeeded (currentDirectory: String) -> Bool {

        let formatConfig = FormatConfig()
        let fileManager = FileManager()

        let plOriginFormatFile = Bundle.main.path(forResource: formatConfig.filename, ofType: nil)!
        // check clang-format config file.
        let usedFormatConfigFile = "\(currentDirectory)/\(formatConfig.filenameDefault)"
        let copyFormatConfigFile = "\(currentDirectory)/\(formatConfig.filename)"

        if fileManager.fileExists(atPath: plOriginFormatFile),
            let originConfigData = fileManager.contents(atPath: plOriginFormatFile),
            originConfigData.count > plkConfigMaxSizeBytes {
            // current config max size `plkConfigMaxSizeBytes`
            return false
        }

        let plOriginConfigFileMd5 = fileManager.contents(atPath: plOriginFormatFile)?.md5()
        let plUsedConfigFileMd5 = fileManager.contents(atPath: usedFormatConfigFile)?.md5()

        if fileManager.fileExists(atPath: copyFormatConfigFile) {

            try? File(path: copyFormatConfigFile).delete()
        }

        let plOriginFile = try! File(path: plOriginFormatFile)
        // print("origin file md5 = \(plOriginConfigFileMd5)\nused file md5 = \(plUsedConfigFileMd5)")

        if plUsedConfigFileMd5 == nil {

            let plDoc = try! Folder(path: currentDirectory)
            if let configFile = try? plOriginFile.copy(to: plDoc) {
                print("#1 copy file success.")

                try? configFile.rename(to: formatConfig.filenameDefault)
            }
            else {
                print("#1 err : copy file failed!")
            }
        }
        else if plUsedConfigFileMd5 != plOriginConfigFileMd5 {

            let plDoc = try! Folder(path: currentDirectory)
            if let configFile = try? plOriginFile.copy(to: plDoc) {
                print("#2 copy file success.")

                try? File(path: usedFormatConfigFile).delete()
                try? configFile.rename(to: formatConfig.filenameDefault)
            }
            else {
                print("#2 err : copy file failed!")
            }
        }

        return true
    }

}
