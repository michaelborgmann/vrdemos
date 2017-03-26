//
//  CardboardViewController.swift
//  VR Demos
//
//  Created by Michael Borgmann on 23/03/2017.
//  Copyright © 2017 Michael Borgmann. All rights reserved.
//

import UIKit

class CardboardViewController: UIViewController, RendererDelegate {
    
    @IBOutlet var cardboardView: GVRCardboardView!
    let renderer = Renderer()
    var renderLoop: RenderLoop?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        renderer.delegate = self
        cardboardView.delegate = renderer
        cardboardView.vrModeEnabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //cardboardView.render()
        //renderLoop = RenderLoop(withRenderer: cardboardView, selector: #selector(getter: render))
        renderLoop = RenderLoop(withRenderer: cardboardView, selector: #selector(cardboardView.render))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
            renderLoop?.invalidate()
            renderLoop = nil
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
