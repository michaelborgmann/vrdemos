//
//  VideoViewController.swift
//  VR Demos
//
//  Created by Michael Borgmann on 22/03/2017.
//  Copyright © 2017 Michael Borgmann. All rights reserved.
//

import UIKit

class VideoViewController: UIViewController {

    @IBOutlet weak var videoView: GVRVideoView!
    var isPlaying = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let url = URL(string: "https://raw.githubusercontent.com/googlevr/gvr-ios-sdk" +
                              "/master/Samples/VideoWidgetDemo/resources/congo.mp4")
        
        // For local resources use this URL instead
        //let path = Bundle.main.path(forResource: "congo", ofType: "mp4")
        //let url = URL(fileURLWithPath: path!)
        
        videoView.load(from: url, of: GVRVideoType.stereoOverUnder)
        videoView.enableFullscreenButton = true
        videoView.enableCardboardButton = true
        videoView.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension VideoViewController: GVRWidgetViewDelegate {
    func widgetView(_ widgetView: GVRWidgetView!, didLoadContent content: Any!) {
        if content is URL {
            videoView.pause()
        }
    }
    
    func widgetView(_ widgetView: GVRWidgetView!, didFailToLoadContent content: Any!, withErrorMessage errorMessage: String!) {
        print("Failed to load content: \(errorMessage)")
    }
    
    
    func widgetView(_ widgetView: GVRWidgetView!, didChange displayMode: GVRWidgetDisplayMode) {
        if displayMode == GVRWidgetDisplayMode.embedded {
            videoView.pause()
            isPlaying = false
        } else {
            videoView.play()
            isPlaying = true
        }
    }
    
    func widgetViewDidTap(_ widgetView: GVRWidgetView!) {
        if videoView.displayMode != .embedded {
            if isPlaying {
                videoView.pause()
            } else {
                videoView.play()
            }
            isPlaying = !isPlaying
        }
    }
}

extension VideoViewController: GVRVideoViewDelegate {
    func videoView(_ videoView: GVRVideoView!, didUpdatePosition position: TimeInterval) {
        if position >= videoView.duration() {
            videoView.seek(to: 0)
            videoView.play()
        }
    }
}
