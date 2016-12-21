import Foundation
import AppKit

import SwiftIpfsApi
import SwiftMultihash

@available(OSX 10.12, *)
class FilesToIPFS : NSObject {

    var logToFile: NSButton!
    var args: [String]!
    var pathLabel: NSTextField!
    
    func main() {
        
        args = CommandLine.arguments as [String]
        print("args were: \(args)")
        
        let alertFrame = NSRect(x: 0, y: 0, width: 400, height: 300)
        let alert = NSAlert()
        alert.messageText = "args were received."
        alert.informativeText = "informative"
        alert.addButton(withTitle: "OK")
        
        
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
        
        view.addSubview(logToFile)
        
        /// Set up path label
        pathLabel = NSTextField(frame: NSRect(x: 0, y: 0, width: hashes.frame.width, height: 20))
        pathLabel.stringValue = "/some/path"
        pathLabel.isEditable = false
        let clickRecognizer = NSClickGestureRecognizer(target: self, action: #selector(FilesToIPFS.changeLogFile))
        pathLabel.addGestureRecognizer(clickRecognizer)
        
        view.addSubview(pathLabel)
        
        alert.accessoryView = view
        
        alert.runModal()
        
        print("Selection was \(hashes.selectedRowIndexes)")
        var filePaths = [String]()
        for i in hashes.selectedRowIndexes {
            print("selected: \(args[i])")
            let filePath = "file://" + args[i]
            filePaths.append(filePath)
        }
        
        generateHashes(from: filePaths) { hashes in
            print("done: \(hashes)")
            
            self.copyToClipboard(hashes: hashes)
            
            exit(EXIT_SUCCESS)
        }
        print("waiting...")
        
        CFRunLoopRun()
    }
    
    
    func changeLogFile() {
        print("cchanges")
        let pathPanel = NSOpenPanel()
        pathPanel.title = "Select new log file."
        pathPanel.canChooseDirectories = false
        pathPanel.canCreateDirectories = false
        pathPanel.allowsMultipleSelection = false
        pathPanel.allowedFileTypes = ["txt"]
        
        if pathPanel.runModal() == NSModalResponseOK {
            /// change the path to the value
            if let result = pathPanel.url {
                pathLabel.stringValue = result.path
            }
        }
    }
    
    func toggleLogToFile() {
        let state = logToFile.state == NSOnState ? "On" : "Off"
        print("toggle \(state)")
        if logToFile.state == NSOffState { pathLabel.isHidden = true } else { pathLabel.isHidden = false }
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
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        print("bo selecta")
    }
}

@available(OSX 10.12, *)
extension FilesToIPFS : NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        print("arg count is \(args.count)")
        return args.count
    }
    
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        print("asking for object for row \(row)")
        return args[row]
    }
}


if #available(OSX 10.12, *) {
    let filesToIPFS = FilesToIPFS()
    filesToIPFS.main()
} else {
    // Fallback on earlier versions
}



