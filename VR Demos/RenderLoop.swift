//
//  RenderLoop.swift
//  VR Demos
//
//  Created by Michael Borgmann on 23/03/2017.
//  Copyright © 2017 Michael Borgmann. All rights reserved.
//

import UIKit

class RenderLoop: NSObject {
    
    var displayLink: CADisplayLink?
    var renderThread: Thread?

    init(withRenderer target: AnyObject, selector sel: Selector) {
        super.init()
        displayLink = CADisplayLink(target: target, selector: sel)
        renderThread = Thread(target: self, selector: #selector(threadMain), object: nil)
        renderThread?.start()
    }
    
    func invalidate() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    func threadMain() {
        displayLink?.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
        CFRunLoopRun()
    }
}
