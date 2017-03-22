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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let margin: CGFloat = 16.0
        let width = view.bounds.width - (2 * margin)
        panoramaView.frame = CGRect(x: margin, y: margin * 4, width: width, height: width / 2)
        view.addSubview(panoramaView)
        
        panoramaView.load(UIImage(named: "andes.jpg"), of: GVRPanoramaImageType.stereoOverUnder)
        panoramaView.enableFullscreenButton = true
        panoramaView.enableCardboardButton = true
        
        //view.addSubview(panoramaView)
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
