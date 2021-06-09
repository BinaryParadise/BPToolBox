//
//  Podable.swift
//  LotusCore
//
//  Created by Rake Yang on 2021/6/9.
//

import Foundation
import Files

class Podable {
    class func setRepo(_ repo: String) -> Void {
        do {
            let f = try Folder(path: NSHomeDirectory()).createSubfolder(at: ".lotus")
            let json = """
            {
                "repo": "\(repo)"
            }
            """
            try f.createFile(at: "config.json").write(json)
            print("set new repo name `\(repo)`")
        } catch {
            print(error)
        }
    }
}
