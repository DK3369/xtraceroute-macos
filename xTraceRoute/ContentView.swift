//
//  ContentView.swift
//  xTraceRoute
//
//  Created by Holger Seelig on 18.12.20.
//

import SwiftUI
import X3D

struct ContentView_Previews : PreviewProvider
{
   static var previews : some View
   {
      ContentView ()
   }
}

struct ContentView :
   View
{
   @State private var hostname : String = ""
   @State private var running  : Bool = false
   
   private var browser = X3DBrowser (url: [Bundle .main .url (forResource: "Earth", withExtension: "x3dv")!], parameter: [])
   
   var body : some View
   {
      VStack (alignment: .leading)
      {
         TextField ("Host name or IP address", text: $hostname, onCommit: onCommit)
            .disabled (running)
         
         browser
      }
      .padding ()
   }
   
   private func onCommit ()
   {
      guard !hostname .isEmpty else { return }
      guard !running else { return }

      DispatchQueue .main .async { running = true }

      // Clear locations
      
      guard let group = try? browser .getExecutionContext () .getNamedNode (name: "Locations") else { return }
      
      let locations = try! group .getField (name: "locations") as! MFNode <X3DNode>
      
      locations .wrappedValue = [ ]
      
      // Start traceroute

      ifconfig ()
      traceroute (hostname)
   }
   
   private func ifconfig ()
   {
      DispatchQueue (label: "create3000.ipinfo", qos: .userInteractive) .async
      {
         let task = Process ()
         let pipe = Pipe ()
         
         task .launchPath     = "/usr/bin/env"
         task .arguments      = ["curl", "ifconfig.me"]
         task .standardOutput = pipe
         task .standardError  = nil
         
         task .launch ()
         
         let fh = pipe .fileHandleForReading
         let ip = fh .readDataToEndOfFile ()
         
         ipinfo (String (decoding: ip, as: UTF8 .self))
      }
   }
   
   private func traceroute (_ hostname : String)
   {
      DispatchQueue (label: "create3000.xtraceroute", qos: .userInteractive) .async
      {
         let task = Process ()
         let pipe = Pipe ()
         
         task .launchPath     = "/usr/bin/env"
         task .arguments      = ["traceroute", "-m", "16", hostname]
         task .standardOutput = pipe
         task .standardError  = nil
         
         task .launch ()
         
         let fh = pipe .fileHandleForReading
         let ip = try! NSRegularExpression (pattern: "(\\d+\\.\\d+\\.\\d+\\.\\d+)")
         
         while let line = fh .readLine ()
         {
            guard let matches = ip .matches (in: line) else { continue }
            
            ipinfo (matches [1])
         }
         
         DispatchQueue .main .async { running = false }
      }
   }
   
   private func ipinfo (_ ipaddress : String)
   {
      DispatchQueue (label: "create3000.ipinfo", qos: .userInteractive) .sync
      {
         let task = Process ()
         let pipe = Pipe ()
         
         task .launchPath     = "/usr/bin/env"
         task .arguments      = ["curl", "ipinfo.io/\(ipaddress)"]
         task .standardOutput = pipe
         task .standardError  = nil
         
         task .launch ()
         
         let fh   = pipe .fileHandleForReading
         let json = fh .readDataToEndOfFile ()
                  
         guard let info = try? JSONSerialization .jsonObject (with: json, options: [ ]) as? [String : String] else
         {
            return
         }

         guard let city = info ["city"],
               let loc  = info ["loc"] else { return }
         
         debugPrint (city, loc)
         
         DispatchQueue .main .sync
         {
            addLocation (loc)
         }
      }
   }
   
   private func addLocation (_ loc : String)
   {
      let coords    = loc .split (separator: ",")
      let scene     = browser .getExecutionContext ()
      let group     = try! scene .getNamedNode (name: "Locations")
      let locations = try! group .getField (name: "locations") as! MFNode <X3DNode>
      let location  = try! scene .createProto (typeName: "Location")
      let latitude  = try! location .getField (name: "latitude")  as! SFFloat
      let longitude = try! location .getField (name: "longitude") as! SFFloat
      
      latitude  .wrappedValue = Float (coords [0]) ?? 0
      longitude .wrappedValue = Float (coords [1]) ?? 0
      
      locations .wrappedValue .append (location)
   }
}

struct IPInfo :
   Decodable
{
   let ip : String
   let city : String
   let region : String
   let country : String
   let loc : String
   let org : String
}

internal extension FileHandle
{
   func readLine (delimiter : String = "\n", encoding : String .Encoding = .utf8, chunkSize : Int = 1) -> String?
   {
      let delimData = delimiter .data (using: encoding)!
      var buffer    = Data ()
      var atEof     = false
      
      // Read data chunks from file until a line delimiter is found:
      while !atEof
      {
         if let range = buffer .range (of: delimData)
         {
            // Convert complete line (excluding the delimiter) to a string:
            let line = String (data: buffer .subdata (in: 0 ..< range .lowerBound), encoding: encoding)
            // Remove line (and the delimiter) from the buffer:
            buffer .removeSubrange (0 ..< range .upperBound)
            
            return line
         }
         
         let tmpData = readData (ofLength: chunkSize)
         
         if tmpData .count > 0
         {
            buffer .append (tmpData)
         }
         else
         {
            // EOF or read error.
            atEof = true
            
            if buffer .count > 0
            {
               // Buffer contains last line in file (not terminated by delimiter).
               let line = String (data: buffer as Data, encoding: encoding)
               
               buffer .count = 0
               
               return line
            }
         }
      }
      
      return nil
   }
}

internal extension NSRegularExpression
{
   func matches (in string : String, all : Bool = false) -> [String]?
   {
      let m = matches (in: string, options: [ ], range: NSRange (location: 0, length: string .utf16 .count))
      var r = [String] ()
      
      guard !m .isEmpty else { return nil }
      
      for m in m
      {
         for index in 0 ..< m .numberOfRanges
         {
            if let range = Range (m .range (at: index), in: string)
            {
               r .append (String (string [range]))
            }
            else
            {
               r .append ("")
            }
         }
         
         if !all { break }
      }
      
      return r
   }
}
