//
//  AppDelegate.swift
//  FilesToIpfs
//
//  Created by Teo Sartori on 30/12/2016.
//  Copyright © 2016 Matteo Sartori. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  
    @IBOutlet weak var window: NSWindow!
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        let f2Ipfs = FilesToIpfs()
        let args = Array<String>(CommandLine.arguments.dropFirst())
        f2Ipfs.set(filePaths: args)
        
        window.contentViewController = f2Ipfs
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        
    }


}

