import Foundation
import AppKit

import SwiftIpfsApi
import SwiftMultihash

@available(OSX 10.12, *)
class FilesToIPFS : NSObject {

    enum TGError : Error {
        case generic(String)
    }
    
    var logToFile: NSButton!
    var args: [String]!
    var pathLabel: NSTextField!
    var alert: NSAlert!
    
    func main() {
        
        args = CommandLine.arguments as [String]
        print("args were: \(args)")
        
        let alertFrame = NSRect(x: 0, y: 0, width: 400, height: 300)
        alert = NSAlert()
        alert.messageText = "Add to IPFS"
        alert.informativeText = "Select files to add to the local IPFS node. The resulting hashes will be also copied to the clipboard."
        alert.addButton(withTitle: "Add")
        
        
        let view = NSView(frame: alertFrame)
        
        /// Set the scroll view a bit above the bottom of the accessory view
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 60, width: alertFrame.size.width, height: 200))
        //scrollView.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]
        scrollView.borderType = .grooveBorder
        scrollView.hasVerticalScroller = true
        
        
        let clipViewBounds = scrollView.contentView.bounds
        
        let hashes = NSTableView(frame: clipViewBounds)
        hashes.allowsMultipleSelection = true
        
        scrollView.documentView = hashes
        
        hashes.delegate = self
        hashes.dataSource = self
        hashes.headerView = nil
        
        let hashesColumn = NSTableColumn(identifier: "hashes")
        hashesColumn.width = clipViewBounds.size.width - 3
        
        hashes.addTableColumn(hashesColumn)
        
        //view.addSubview(hashes)
        view.addSubview(scrollView)
        
        /// This is necessary for selections and off-view cells to be drawn.
        view.wantsLayer = true

        /// We need a text field to fill with the hashes
        logToFile = NSButton(checkboxWithTitle: "Log to file", target: self, action: #selector(FilesToIPFS.toggleLogToFile))
        logToFile.frame.origin = CGPoint(x: 0, y: 30)
        logToFile.state = UserDefaults.standard.object(forKey: "FilesToIPFSLogPreference") as? Int ?? NSOffState
            
        view.addSubview(logToFile)
        
        /// Set up path label
        pathLabel = NSTextField(frame: NSRect(x: 0, y: 0, width: hashes.frame.width, height: 20))
        /// See if the user has previously stored a log file path
        pathLabel.stringValue = UserDefaults.standard.object(forKey: "FilesToIPFSLogFilePath") as? String ?? ""
        pathLabel.isEditable = false
        pathLabel.isHidden = logToFile.state == NSOffState ? true : false
        
        let clickRecognizer = NSClickGestureRecognizer(target: self, action: #selector(FilesToIPFS.changeLogFile))
        pathLabel.addGestureRecognizer(clickRecognizer)
        
        view.addSubview(pathLabel)
        
        alert.accessoryView = view
        
        alert.runModal()
        
        
        guard let selectees = (args as NSArray).objects(at: hashes.selectedRowIndexes) as? [String], selectees.count > 0 else { return }
        
        let filePaths = selectees.map { "file://" + $0 }
        
        generateHashes(from: filePaths) { hashes in
            
            self.copyToClipboard(hashes: hashes)
    
            if self.logToFile.state == NSOffState { exit(EXIT_SUCCESS) }
            
            self.storeToLog(hashes: hashes, filePaths: filePaths)
        }
        print("waiting...")
        
        CFRunLoopRun()
    }
    
    func storeToLog(hashes: [String], filePaths: [String]) {
        do {
            
            guard FileManager.default.fileExists(atPath: self.pathLabel.stringValue) == true else {
                throw TGError.generic("Error: log file not found")
            }
            
            let entries = try self.formatHashes(hashes: hashes, paths: filePaths)
            print("formatted: \(entries)")
            
            let validURL = URL(fileURLWithPath: self.pathLabel.stringValue)
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
    
    func changeLogFile() {
        
        let pathPanel = NSOpenPanel()
        pathPanel.title = "Log file selector"
        pathPanel.message = "Select log file"
        pathPanel.directoryURL = URL(fileURLWithPath: "/Users/teo")
        
        pathPanel.canChooseDirectories = false
        pathPanel.canCreateDirectories = false
        pathPanel.allowsMultipleSelection = false
        pathPanel.allowedFileTypes = ["txt"]
        
        /// Force the open panel to appear on top of the alert dialog.
        for win in NSApp.windows {
            if win.isKind(of: NSOpenPanel.self) { win.level = alert.window.level + 1 }
        }
        
        if pathPanel.runModal() == NSModalResponseOK {
            /// change the path to the value
            if let result = pathPanel.url {
                pathLabel.stringValue = result.path
                
                /// Store the path label
                UserDefaults.standard.setValue(pathLabel.stringValue, forKey: "FilesToIPFSLogFilePath")
            }
        }
    }
    
    func toggleLogToFile() {
        let state = logToFile.state == NSOnState ? "On" : "Off"
        print("toggle \(state)")
        if logToFile.state == NSOffState { pathLabel.isHidden = true } else { pathLabel.isHidden = false }
        UserDefaults.standard.setValue(logToFile.state, forKey: "FilesToIPFSLogPreference")
    }
    
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
    func generateHashes(from filePaths: [String], completionHandler: @escaping ([String]) -> Void ) {
        // FIXME: Ensure there actually are files at the filePaths.
        var hashes = [String]()
        
        do {
            let api = try IpfsApi(host: "127.0.0.1", port: 5001)

            try api.add(filePaths) { result in
                
                for index in 0 ..< filePaths.count {
                    hashes.append(b58String(result[index].hash!))
                }
                
                completionHandler(hashes)
                
            }
        } catch {
            print("error \(error)")
            return
        }
    }
}

@available(OSX 10.12, *)
extension FilesToIPFS : NSTableViewDelegate {
    
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        print("ping")
        
        var txtView: NSTextField? = tableView.make(withIdentifier: "arsetext", owner: self) as? NSTextField
            
        if txtView == nil {
            
//            txtView = NSTextField(frame: NSRect(origin: CGPoint.zero, size: tableView.frame.size))
            txtView = NSTextField()
            txtView?.identifier = "arsetext"
            print("was nil \(Date())")
        }

        txtView?.stringValue = args[row]
        
        return txtView
    }
 
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 20.0
    }
    
//    func tableViewSelectionDidChange(_ notification: Notification) {
//        print("bo selecta")
//    }
}

@available(OSX 10.12, *)
extension FilesToIPFS : NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        //print("arg count is \(args.count)")
        return args.count
    }
    
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        //print("asking for object for row \(row)")
        return args[row]
    }
}


if #available(OSX 10.12, *) {
    let filesToIPFS = FilesToIPFS()
    filesToIPFS.main()
} else {
    // Fallback on earlier versions
}



