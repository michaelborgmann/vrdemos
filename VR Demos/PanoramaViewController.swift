//
//  PanoramaViewController.swift
//  VR Demos
//
//  Created by Michael Borgmann on 21/03/2017.
//  Copyright © 2017 Michael Borgmann. All rights reserved.
//

import UIKit

class PanoramaViewController: UIViewController {

    let panoramaView = GVRPanoramaView()
    
    var photos = ["andes.jpg", "coral.jpg"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let margin: CGFloat = 16.0
        let width = view.bounds.width - (2 * margin)
        panoramaView.frame = CGRect(x: margin, y: margin * 4, width: width, height: width / 2)
        view.addSubview(panoramaView)
        
        panoramaView.load(UIImage(named: photos.first!), of: GVRPanoramaImageType.stereoOverUnder)
        panoramaView.enableFullscreenButton = true
        panoramaView.enableCardboardButton = true
        panoramaView.delegate = self
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

extension PanoramaViewController: GVRWidgetViewDelegate {

    public func widgetView(_ widgetView: GVRWidgetView!, didLoadContent content: Any!) {
        if content is UIImage {
            panoramaView.enableTouchTracking = false
        }
    }
    
    public func widgetView(_ widgetView: GVRWidgetView!, didFailToLoadContent content: Any!, withErrorMessage errorMessage: String!) {
        print("Failed to load content: \(errorMessage)")
    }
    
    public func widgetView(_ widgetView: GVRWidgetView!, didChange displayMode: GVRWidgetDisplayMode) {
        if displayMode == GVRWidgetDisplayMode.fullscreen {
            panoramaView.enableTouchTracking = true
            view.isHidden = true
            tabBarController?.tabBar.isHidden = true
        } else {
            panoramaView.enableTouchTracking = false
            view.isHidden = false
            tabBarController?.tabBar.isHidden = false
        }
    }
    
    public func widgetViewDidTap(_ widgetView: GVRWidgetView!) {
        photos.append(photos.removeFirst())
        panoramaView.load(UIImage(named: photos.first!), of: GVRPanoramaImageType.stereoOverUnder)
    }
}
