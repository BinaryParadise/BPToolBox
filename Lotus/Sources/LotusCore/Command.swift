//
//  Command.swift
//  LotusCore
//
//  Created by Rake Yang on 2021/6/9.
//

import ArgumentParser
import Foundation

struct Lotus: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "",
                                                    subcommands: [Pod.self, Confuse.self])
    
    struct Pod: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Pod仓库发布版本")
        
        @Option(name: .shortAndLong, help: "设置spec仓库名称")
        var repo: String?
        
        func run() throws {
            if let repo = repo {
                Podable.setRepo(repo)
            }
        }
    }
    
    struct Confuse: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "混淆、资源整理")
        
        func run() throws {
            print("confuse")
        }
    }
}

@discardableResult func runShell(command: String) -> Int32 {
    let proc = Process()
    proc.launchPath = "/bin/bash"
    proc.arguments = ["-c", "git status"]
    proc.launch()
    proc.waitUntilExit()
    return proc.terminationStatus
}
