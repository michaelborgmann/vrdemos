//
//  PanoramaViewController.swift
//  VR Demos
//
//  Created by Michael Borgmann on 21/03/2017.
//  Copyright © 2017 Michael Borgmann. All rights reserved.
//

import UIKit

class PanoramaViewController: UIViewController {

    @IBOutlet weak var panoramaView: GVRPanoramaView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        panoramaView.load(UIImage(named: "andes.jpg"), of: GVRPanoramaImageType.stereoOverUnder)
        panoramaView.enableFullscreenButton = true
        panoramaView.enableCardboardButton = true
        
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
