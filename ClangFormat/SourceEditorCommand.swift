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
    
    let plConfig = FormatConfig()
    
    var commandPath: String {
        return Bundle.main.path(forResource: "clang-format", ofType: nil)!
    }

    static func run(_ commandPath: String, arguments: [String], stdin: String) -> String? {
        let formatConfig = FormatConfig()

        let plBundlePath = Bundle.main.bundlePath
        let plOriginFormatFile = "\(plBundlePath)/Contents/Resources/\(formatConfig.filename)"
        
        let errorPipe = Pipe()
        let outputPipe = Pipe()
 
        let task = Process()
        task.standardError = errorPipe
        task.standardOutput = outputPipe
        task.launchPath = commandPath
        task.arguments = arguments
        
        // check clang-format config file.
        let currentDirectory = task.currentDirectoryPath
        let usedFormatConfigFile = "\(currentDirectory)/\(FormatConfig().filenameDefault)"
        let copyFormatConfigFile = "\(currentDirectory)/\(FormatConfig().filename)"
        if FileManager().fileExists(atPath: copyFormatConfigFile) {
            
            try? File(path: copyFormatConfigFile).delete()
        }
        
        let plFile = try! File(path: plOriginFormatFile)
        
        let plUsedFile = try! File(path: usedFormatConfigFile)
//        if plFile == plUsedFile {
//            print("origin File == used File.")
//        }
        
        let plOriginConfigFileMd5 = StringProxy(proxy: plOriginFormatFile).md5
        let plUsedConfigFileMd5 = StringProxy(proxy: usedFormatConfigFile).md5
        
//        let plOriginConfigFileMd5 = HashProtocol(proxy: plOriginFormatFile).md5
//        let plUsedConfigFileMd5 = HashProtocol(proxy: usedFormatConfigFile).md5
    
        if !FileManager().fileExists(atPath: usedFormatConfigFile) {
            
            let plDoc = try! Folder(path: currentDirectory)
            if let configFile = try? plFile.copy(to: plDoc) {
                print("#1 copy file success.")
                
                try? configFile.rename(to: formatConfig.filenameDefault)
            }
            else {
                print("#1 err : copy file failed!")
            }
        }
        else if plUsedConfigFileMd5 != plOriginConfigFileMd5 {
        
            let plDoc = try! Folder(path: currentDirectory)
            if let configFile = try? plFile.copy(to: plDoc) {
                print("#2 copy file success.")
                
                try? File(path: usedFormatConfigFile).delete()
                try? configFile.rename(to: formatConfig.filenameDefault)
            }
            else {
                print("#2 err : copy file failed!")
            }
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
                                                      arguments: [ "-style=file", "-assume-filename=\(plConfig.language)" ],
//                                                        arguments: [ "-style=file", "-assume-filename=Objective-C" ],
                                                      stdin: invocation.buffer.completeBuffer),
            invocation.buffer.contentUTI == "public.objective-c-source" {
            
            invocation.buffer.completeBuffer = outputString
        }

        completionHandler(nil)
    }
    
    
}
