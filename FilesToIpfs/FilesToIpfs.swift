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
    @IBOutlet weak var filePathTable: NSTableView!
    
    var args: [String]!
    
    public func set(filePaths: [String]) {
        args = filePaths
        print("args is \(args)")
    }
    
    override func viewDidLoad() {
        
        /// set up a gesture recognizer for the view's path field
        let clickRecognizer = NSClickGestureRecognizer(target: self, action: #selector(FilesToIpfs.changeLogFilepath))
        filesToIpfsView.pathToLogfile.addGestureRecognizer(clickRecognizer)

        filesToIpfsView.logState = UserDefaults.standard.object(forKey: "FilesToIpfsLogPreference") as? Int ?? NSOffState
        filesToIpfsView.logPath = UserDefaults.standard.object(forKey: "FilesToIpfsLogFilePath") as? String ?? ""
    }
    
    func changeLogFilepath() {
        let pathPanel = NSOpenPanel()
        pathPanel.title = "Log file selector"
        pathPanel.message = "Select log file"
        pathPanel.directoryURL = URL(fileURLWithPath: "/Users/teo")
        
        pathPanel.canChooseDirectories = false
        pathPanel.canCreateDirectories = false
        pathPanel.allowsMultipleSelection = false
        pathPanel.allowedFileTypes = ["txt"]
        
        if pathPanel.runModal() == NSModalResponseOK {
            /// change the path to the value
            if let result = pathPanel.url {
                filesToIpfsView.logPath = result.path
                /// Store the path label
                UserDefaults.standard.setValue(filesToIpfsView.logPath, forKey: "FilesToIpfsLogFilePath")
            }
        }
    }
    
    ////////////////////////
    func storeToLog(hashes: [String], filePaths: [String]) {
        do {
            
            guard FileManager.default.fileExists(atPath: filesToIpfsView.logPath) == true else {
                throw TGError.generic("Error: log file not found")
            }
            
            let entries = try self.formatHashes(hashes: hashes, paths: filePaths)
            print("formatted: \(entries)")
            
            let validURL = URL(fileURLWithPath: filesToIpfsView.logPath)
            try self.append(entries: entries, to: validURL)
            
            exit(EXIT_SUCCESS)
            
        } catch {
            print("Error: \(error)")
            exit(EXIT_FAILURE)
        }
        
    }
    
    func selectedFiles(selectedIndexes: IndexSet, from files: [String]) -> [String] {
        
        var filePaths = [String]()
        for i in selectedIndexes {
            
            let filePath = "file://" + args[i]
            filePaths.append(filePath)
        }
        return filePaths
    }
    
    func formatHashes(hashes: [String], paths: [String]) throws -> [String] {
        
        guard hashes.count == paths.count else { throw TGError.generic("hashes and paths don't match") }
        
        let locDate = DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .long)
        
        let hashEntries = hashes.enumerated().map { (index, element) -> String in
            
            let filename = NSString(string: paths[index]).lastPathComponent
            
            return "\nadded \(element) \(filename) \(locDate)"
        }
        
        return hashEntries
    }
    
    func append(entries: [String], to file: URL) throws {
        
        let fileHandle = try FileHandle(forWritingTo: file)
        defer { fileHandle.closeFile() }
        
        fileHandle.seekToEndOfFile()
        for entry in entries {
            if let dat = entry.data(using: .utf8) {
                fileHandle.write(dat)
            }
        }
    }
    
    
//    func toggleLogToFile() {
//        let state = logToFile.state == NSOnState ? "On" : "Off"
//        
//        if logToFile.state == NSOffState { pathLabel.isHidden = true } else { pathLabel.isHidden = false }
//        UserDefaults.standard.setValue(logToFile.state, forKey: "FilesToIPFSLogPreference")
//    }
    
    func textView(_ textView: NSTextView, clickedOn cell: NSTextAttachmentCellProtocol, in cellFrame: NSRect, at charIndex: Int) {
        print("click")
    }
    
    func copyToClipboard(hashes: [String]) {
        /// Write the selected hashes to the system pasteboard.
        if hashes.count > 0 {
            let pb = NSPasteboard.general()
            pb.clearContents()
            pb.writeObjects(hashes as [NSPasteboardWriting])
        }
    }
    
    /// Asynchronously generate hashes from the given filepaths.
    /// Calls the handler on success.
//    func generateHashes(from filePaths: [String], completionHandler: @escaping ([String]) -> Void ) {
//        // FIXME: Ensure there actually are files at the filePaths.
//        var hashes = [String]()
//        
//        do {
//            let api = try IpfsApi(host: "127.0.0.1", port: 5001)
//            
//            try api.add(filePaths) { result in
//                
//                for index in 0 ..< filePaths.count {
//                    hashes.append(b58String(result[index].hash!))
//                }
//                
//                completionHandler(hashes)
//                
//            }
//        } catch {
//            print("error generating hashes \(error)")
//            exit(EXIT_FAILURE)
//        }
//    }
    ///////////////////////
    
    @IBAction func addAction(_ sender: NSButton) {
        Swift.print("add")
        
        guard let selectees = (args as NSArray).objects(at: filePathTable.selectedRowIndexes) as? [String], selectees.count > 0 else { return }
        
        let filePaths = selectees.map { "file://" + $0 }
        print("filepaths \(filePaths)")
//        generateHashes(from: filePaths) { hashes in
//            
//            self.copyToClipboard(hashes: hashes)
//            
//            if self.filesToIpfsView.logState == NSOffState { exit(EXIT_SUCCESS) }
//            
//            self.storeToLog(hashes: hashes, filePaths: filePaths)
//        }
        
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
        return args.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return args[row]
    }
}


class FilesToIpfsView : NSView {
    
    @IBOutlet weak var pathToLogfile: NSTextField!
    @IBOutlet weak var logToFile: NSButton!

    var logState: Int {
        set {
            logToFile.state = newValue
            pathToLogfile.isHidden = (newValue == NSOffState)
        }
        get { return logToFile.state }
    }
    
    var logPath: String {
        set {
            pathToLogfile.stringValue = newValue
        }
        get { return pathToLogfile.stringValue }
    }
    
    @IBAction func logToFile(_ sender: NSButton) {
        
        pathToLogfile.isHidden = (logToFile.state == NSOffState)
        
        UserDefaults.standard.setValue(logToFile.state, forKey: "FilesToIpfsLogPreference")

    }
    
    @IBAction func cancelAction(_ sender: NSButton) {
        Swift.print("cancel")
    }
    
    
    
    @IBAction func changePathToLogfile(_ sender: NSTextField) {
        Swift.print("change path")
    }    
}
