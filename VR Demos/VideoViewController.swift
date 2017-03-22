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
