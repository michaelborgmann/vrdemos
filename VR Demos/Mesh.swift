//
//  Mesh.swift
//  VR Demos
//
//  Created by Michael Borgmann on 02.04.17.
//  Copyright © 2017 Michael Borgmann. All rights reserved.
//

import Foundation
import SwiftyJSON

struct Mesh {
    
    var json: JSON? = nil
    
    init(fileNamed: String) {
        if let file = Bundle.main.path(forResource: fileNamed, ofType: "json") {
            do {
                let url = URL(fileURLWithPath: file)
                let data = try Data(contentsOf: url)
                json = JSON(data: data)
            } catch {
                print("Can't load JSON file")
            }
        }
    }
    
    var vertices: [GLfloat] {
        get {
            var vertices = [GLfloat]()
            
            guard let verticesJSON = (json?["vertices"].arrayValue.map({$0.doubleValue})) else {
                return vertices
            }
            
            for i in 0..<verticesJSON.count {
                vertices.append(GLfloat(verticesJSON[i] * size))
            }
            
            return vertices
        }
    }
    
    var colors: [GLfloat] {
        get {
            var colors = [GLfloat]()
            
            guard let colorsJSON = (json?["colors"].arrayValue.map({$0.doubleValue})) else {
                return colors
            }
            
            for i in 0..<colorsJSON.count {
                colors.append(GLfloat(colorsJSON[i] * size))
            }
            
            return colors
        }
    }
    
    var foundColors: [GLfloat] {
        get {
            var foundColors = [GLfloat]()
            
            guard let foundColorsJSON = (json?["foundColors"].arrayValue.map({$0.doubleValue})) else {
                return foundColors
            }
            
            for i in 0..<foundColorsJSON.count {
                foundColors.append(GLfloat(foundColorsJSON[i] * size))      // NOTE: here may hide a bug
            }
            
            return foundColors
        }
    }
    
    var position = [GLfloat]()
    
    var program: GLuint = 0
    var vertexAttribute: GLint = 0
    var colorAttribute: GLint = 0
    var mvpMatrix: GLint = 0
    var positionUniform: GLint = 0
    var vertexBuffer: GLuint = 0
    var colorBuffer: GLuint = 0
    var foundColorBuffer: GLuint = 0
    
    let size = 1.0
    let minDistance = 2.0
    let maxDistance = 7.0
    let azimuthRadians = 2.0 * Double.pi
    let elevationRadians = 0.25 * Double.pi
    let thresholdRadians = 0.5
}
