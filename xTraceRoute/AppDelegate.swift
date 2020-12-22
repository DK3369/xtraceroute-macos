//
//  AppDelegate.swift
//  xTraceRoute
//
//  Created by Holger Seelig on 18.12.20.
//

import Cocoa
import SwiftUI
import X3D

@main
internal final class AppDelegate :
   NSObject,
   NSApplicationDelegate
{
   final private var window                       : NSWindow!
   final private var contentView                  : ContentView!
   @IBOutlet final private weak var earthMenuItem : NSMenuItem!
   
   final private lazy var studioScene : X3DScene =
   {
      try! contentView .browser .createX3DFromURL (url: [Bundle .main .url (forResource: "x-scene", withExtension: "x3dv")!])
   }()
   
   final private lazy var classicScene : X3DScene =
   {
      try! contentView .browser .createX3DFromURL (url: [Bundle .main .url (forResource: "scene", withExtension: "x3dv")!])
   }()

   internal final func applicationDidFinishLaunching (_ aNotification : Notification)
   {
      // Create the SwiftUI view that provides the window contents.
      contentView = ContentView ()
      
      contentView .browser .replaceWorld (scene: studioScene)
      
      // Create the window and set the content view.
      window = NSWindow (contentRect: NSRect (x: 0, y: 0, width: 480, height: 480),
                         styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                         backing: .buffered,
                         defer: false)
      
      window .title                = Bundle .main .infoDictionary! ["CFBundleName"] as! String
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
   
   @IBAction func onEarthToggled (_ menuItem : NSMenuItem)
   {
      if menuItem .state == .off
      {
         menuItem .state = .on
         
         contentView .browser .replaceWorld (scene: classicScene)
      }
      else
      {
         menuItem .state = .off
         
         contentView .browser .replaceWorld (scene: studioScene)
      }
      
      // Clear locations.
      
      guard let group = try? contentView .browser .getExecutionContext () .getNamedNode (name: "Locations") else { return }
      
      let locations = try! group .getField (name: "locations") as! MFNode <X3DNode>
      
      locations .wrappedValue = [ ]
   }
}
