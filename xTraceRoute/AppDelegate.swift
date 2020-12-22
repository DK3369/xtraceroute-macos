//
//  AppDelegate.swift
//  xTraceRoute
//
//  Created by Holger Seelig on 18.12.20.
//

import Cocoa
import SwiftUI

@main
class AppDelegate :
   NSObject,
   NSApplicationDelegate
{
   var window : NSWindow!
   
   internal final func applicationDidFinishLaunching (_ aNotification : Notification)
   {
      // Create the SwiftUI view that provides the window contents.
      let contentView = ContentView ()
      
      // Create the window and set the content view.
      window = NSWindow (contentRect: NSRect (x: 0, y: 0, width: 480, height: 480),
                         styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                         backing: .buffered,
                         defer: false)
      
      window .title                = "xTraceRoute"
      window .tabbingMode          = .disallowed
      window .isReleasedWhenClosed = false
      window .contentView          = NSHostingView (rootView: contentView)
      
      window .setFrameAutosaveName ("Main Window")
      window .center ()
      window .makeKeyAndOrderFront (nil)
   }
   
   internal final func applicationWillTerminate (_ aNotification : Notification)
   {
      // Insert code here to tear down your application
   }

   internal final func applicationShouldTerminateAfterLastWindowClosed (_ sender : NSApplication) -> Bool
   {
       return true
   }
}

