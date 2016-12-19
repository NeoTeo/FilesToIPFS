import Foundation
import AppKit


@available(OSX 10.12, *)
class FilesToIPFS : NSObject {

    var args: [String]!
    
    func main() {
        
        args = CommandLine.arguments as [String]
        print("args were: \(args)")
        
        let alertFrame = NSRect(x: 0, y: 0, width: 400, height: 300)
        let alert = NSAlert()
        alert.messageText = "args were received."
        alert.addButton(withTitle: "OK")
        
        let view = NSView(frame: alertFrame)
        print("translates? \(view.translatesAutoresizingMaskIntoConstraints)")
        
        
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 200, height: 200))
        //scrollView.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]
        scrollView.borderType = .grooveBorder
        scrollView.hasVerticalScroller = true
        
        
        let clipViewBounds = scrollView.contentView.bounds
        
        let hashes = NSTableView(frame: clipViewBounds)
        hashes.allowsMultipleSelection = true
        //hashes.sizeLastColumnToFit()
        hashes.sizeToFit()
        
        scrollView.documentView = hashes
        
        hashes.delegate = self
        hashes.dataSource = self
        let hashesColumn = NSTableColumn(identifier: "hashes")
        
        hashes.headerView = nil
        //hashesColumn.headerCell.title = "Hashes"
        hashesColumn.width = 100
        
        hashes.addTableColumn(hashesColumn)
        
        //view.addSubview(hashes)
        view.addSubview(scrollView)
        
        /// We need a text field to fill with the hashes
        //view.addSubview(NSButton(checkboxWithTitle: "tick", target: nil, action: nil))
        alert.accessoryView = view
        
        alert.runModal()
        
        print("Selection was \(hashes.selectedRowIndexes)")
        print("done")
    //    CFRunLoopRun()
    }
    
    func textView(_ textView: NSTextView, clickedOn cell: NSTextAttachmentCellProtocol, in cellFrame: NSRect, at charIndex: Int) {
        print("click")
    }
}

@available(OSX 10.12, *)
extension FilesToIPFS : NSTableViewDelegate {
    
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        print("ping")
        var txtView: NSTextField? = tableView.make(withIdentifier: "arsetext", owner: self) as? NSTextField
            
        if txtView == nil {
            txtView = NSTextField(frame: NSRect(x: 0, y: 0, width: 50, height: 30))
            txtView?.identifier = "arsetext"
            print("was nil \(Date())")
        }

        txtView?.stringValue = args[row]
        
        return txtView
    }
 
    
    /*
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var cellView = tableView.make(withIdentifier: "arsetext", owner: self) as? NSTableCellView
        
        if cellView == nil {
            cellView = NSTableCellView(frame: NSRect(x: 0, y: 0, width: 50, height: 30))

            cellView?.identifier = "arsetext"
            print("was nil \(Date())")
        }
        
        cellView?.textField?.stringValue = args[row]
        return cellView
    }
 */
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 20.0
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



