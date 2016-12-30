//
//  FilesToIpfs.swift
//  FilesToIpfs
//
//  Created by Teo Sartori on 30/12/2016.
//  Copyright © 2016 Matteo Sartori. All rights reserved.
//

import Foundation
import AppKit

//import SwiftIpfsApi
//import SwiftMultihash

class FilesToIpfs : NSViewController {
    
    enum TGError : Error {
        case generic(String)
    }
    
    @IBOutlet var filesToIpfsView: FilesToIpfsView!
    
    var args: [String]!
    
    public func set(filePaths: [String]) {
        args = filePaths
        print("wtf \(self)")
        print("args is \(args)")
    }
    
    override func viewDidLoad() {
        print("tada")
    }
    
    override func awakeFromNib() {
        print("awake")
    }
}

extension FilesToIpfs : NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var txtView: NSTextField? = tableView.make(withIdentifier: "fileField", owner: self) as? NSTextField
        
        if txtView == nil {
            
            txtView = NSTextField()
            txtView?.identifier = "fileField"
        }
        
        txtView?.stringValue = args[row]
        
        return txtView
    }
    
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 20.0
    }
    
}

@available(OSX 10.12, *)
extension FilesToIpfs : NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        print("wtf \(self)")
        return args.count
    }
    
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return args[row]
    }
}


class FilesToIpfsView : NSView {
    @IBOutlet weak var pathToLogfile: NSTextField!
    
    
    @IBAction func logToFile(_ sender: NSButton) {
        Swift.print("log toggle")
    }
    
    @IBAction func cancelAction(_ sender: NSButton) {
        Swift.print("cancel")
    }
    
    @IBAction func addAction(_ sender: NSButton) {
        Swift.print("add")
    }
    
    
    @IBAction func changePathToLogfile(_ sender: NSTextField) {
        Swift.print("change path")
    }    
}
