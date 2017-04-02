//
//  Renderer.swift
//  VR Demos
//
//  Created by Michael Borgmann on 23/03/2017.
//  Copyright © 2017 Michael Borgmann. All rights reserved.
//

import UIKit
import OpenGLES

@objc protocol RendererDelegate {
    @objc optional func shouldPauseRenderLoop(pause: Bool)
}

class Renderer: NSObject, GVRCardboardViewDelegate {
    
    var delegate: RendererDelegate?
    
    var cube = Mesh(fileNamed: "cube")
    var grid = Mesh(fileNamed: "grid")
    
    var isCubeFocues = false

    // MARK: Implement GVRCardboardViewDelegate
    
    func cardboardView(_ cardboardView: GVRCardboardView!, willStartDrawing headTransform: GVRHeadTransform!) {
        // Renderer must be created before any call to drawFrame.
        
        // 1. Load the vertex/fragment shader"
        guard let vertexShaderFile = Bundle.main.path(forResource: "Vertex", ofType: "vsh"),
              let fragmentShaderFile = Bundle.main.path(forResource: "Fragment", ofType: "fsh"),
              let gridFragmentShaderFile = Bundle.main.path(forResource: "GridFragment", ofType: "fsh") else {
            fatalError("File not found")
        }
        
        let vertexShader = CompileShader(type: GLenum(GL_VERTEX_SHADER), shaderFile: vertexShaderFile)
        assert(vertexShader != 0, "Failed to load vertex shader")
        
        let fragmentShader = CompileShader(type: GLenum(GL_FRAGMENT_SHADER), shaderFile: fragmentShaderFile)
        assert(fragmentShader != 0, "Failed to load fragment shader")
        
        let gridFragmentShader = CompileShader(type: GLenum(GL_FRAGMENT_SHADER), shaderFile: gridFragmentShaderFile)
        assert(gridFragmentShader != 0, "Failed to load grid fragment shader")
        
        createMesh(&cube, vertexShader, fragmentShader)
        createMesh(&grid, vertexShader, gridFragmentShader)
        setGridPosition()
        
        // TODO: Initialize GVRCardboardAudio engine
        
        // Generate seed for random number generation.
        srand48(Int(NSDate().timeIntervalSinceReferenceDate))

        // Spawn the firs cube
        spawnCube()
        // TODO: implement audio
    }
    
    func cardboardView(_ cardboardView: GVRCardboardView!, prepareDrawFrame headTransform: GVRHeadTransform!) {
        let headRotation = GLKQuaternionMakeWithMatrix4(headTransform.headPoseInStartSpace())
        // TODO: implement audio
        
        let sourceCubePosition = GLKVector3Make(cube.position[0], cube.position[1], cube.position[2])
        isCubeFocues = isLookingAtObject(headRotation: headRotation, sourcePosition: sourceCubePosition)
        
        glClearColor(0.0, 0.0, 0.0, 1.0)
        glEnable(GLenum(GL_DEPTH_TEST))
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
        glEnable(GLenum(GL_SCISSOR_TEST))
    }
    
    func cardboardView(_ cardboardView: GVRCardboardView!, draw eye: GVREye, with headTransform: GVRHeadTransform!) {
        let viewport = headTransform.viewport(for: eye)
        glViewport(GLint(viewport.origin.x), GLint(viewport.origin.y),
                   GLsizei(viewport.size.width), GLsizei(viewport.size.height))
        glScissor(GLint(viewport.origin.x), GLint(viewport.origin.y),
                  GLsizei(viewport.size.width), GLsizei(viewport.size.height))
        
        let headFromStartMatrix = headTransform.headPoseInStartSpace()
        
        let projectionMatrix = headTransform.projectionMatrix(for: eye, near: 0.1, far: 100.0)
        let eyeFromHeadMatrix = headTransform.eye(fromHeadMatrix: eye)
        
        var modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, GLKMatrix4Multiply(eyeFromHeadMatrix, headFromStartMatrix))
        
        if isCubeFocues {
                renderWithModelViewProjectionMatrix(mesh: cube, modelViewMatrix: &modelViewProjectionMatrix.m, colorBuffer: cube.foundColorBuffer)
        } else {
                renderWithModelViewProjectionMatrix(mesh: cube, modelViewMatrix: &modelViewProjectionMatrix.m, colorBuffer: cube.colorBuffer)
        }
        
        renderWithModelViewProjectionMatrix(mesh: grid, modelViewMatrix: &modelViewProjectionMatrix.m)
    }
    
    func cardboardView(_ cardboardView: GVRCardboardView!, didFire event: GVRUserEvent) {
        
    }
    
    func cardboardView(_ cardboardView: GVRCardboardView!, shouldPauseDrawing pause: Bool) {
        
    }
    
    // MARK: Helper Methods
    
    func createMesh(_ mesh: inout Mesh, _ vertexShader: GLuint, _ fragmentShader: GLuint) {
        createProgram(program: &mesh.program, vertexShader: vertexShader, fragmentShader: fragmentShader)
        getAttributeLoction(program: &mesh.program, vertexAttribute: &mesh.vertexAttribute, colorAttribute: &mesh.colorAttribute)
        getUniforms(program: &mesh.program, mvpMatrix: &mesh.mvpMatrix, positionUniform: &mesh.positionUniform)
        
        createMeshData(mesh: mesh.vertices, buffer: &mesh.vertexBuffer)
        createMeshData(mesh: mesh.colors, buffer: &mesh.colorBuffer)
        createMeshData(mesh: mesh.foundColors, buffer: &mesh.foundColorBuffer)
    }
    
    func setGridPosition() {
        grid.position.append(0)
        grid.position.append(-20.0)
        grid.position.append(0)
    }
    
    func spawnCube() {
        setRandomCubePosition(min: cube.minDistance, maxLimit: cube.maxDistance)
        // TODO: implement audio
    }
    
    func setRandomCubePosition(min: Double, maxLimit max: Double) {
        let distance = min + ((max - min) * drand48())
        let azimuth = drand48() *  cube.azimuthRadians
        let elevation = (2.0 * drand48() * cube.elevationRadians) - cube.elevationRadians
        
        cube.position.append(GLfloat(-cos(elevation) * sin(azimuth) * distance))
        cube.position.append(GLfloat(sin(elevation) * distance))
        cube.position.append(GLfloat(-cos(elevation) * cos(azimuth) * distance))
    }
    
    func isLookingAtObject(headRotation: GLKQuaternion, sourcePosition position: GLKVector3) -> Bool {
        let sourceDirection = GLKQuaternionRotateVector3(GLKQuaternionInvert(headRotation), position)
        return Double(abs(sourceDirection.v.0)) < cube.thresholdRadians &&
               Double(abs(sourceDirection.v.1)) < cube.thresholdRadians
    }
    
    func renderWithModelViewProjectionMatrix(mesh: Mesh, modelViewMatrix: inout (Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float), colorBuffer: GLuint? = nil) {
        
        // 1. Select shader
        glUseProgram(mesh.program)
        
        // 2. Set the uniform values that will be used by the shader
        glUniform3fv(mesh.positionUniform, 1, mesh.position)
        
        // 3. Set the uniform matrix values that will be used by our shader
        withUnsafeMutablePointer(to: &modelViewMatrix) {
            $0.withMemoryRebound(to: GLfloat.self, capacity: MemoryLayout.size(ofValue: modelViewMatrix) , {
                glUniformMatrix4fv(mesh.mvpMatrix, 1, GLboolean(false), UnsafePointer<GLfloat>($0)!)
            })
        }
        
        // 4. Set colors
        let colorBuffer = colorBuffer ?? mesh.colorBuffer
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), colorBuffer)     // TODO: isCubeFocused?
        
        glVertexAttribPointer(GLuint(mesh.colorAttribute), 4, GLenum(GL_FLOAT), GLboolean(GL_FALSE),
                              GLsizei(MemoryLayout<Float>.stride * 4),
                              UnsafeRawPointer(bitPattern: 0))
        glEnableVertexAttribArray(GLuint(mesh.colorAttribute))

        // 5. Draw polygons
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), mesh.vertexBuffer)
        glVertexAttribPointer(GLuint(mesh.vertexAttribute), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE),
                              GLsizei(MemoryLayout<Float>.stride * 3),
                              UnsafeRawPointer(bitPattern: 0))
        glEnableVertexAttribArray(GLuint(mesh.vertexAttribute))
        glDrawArrays(GLenum(GL_TRIANGLES), 0, GLsizei(mesh.vertices.count / 3))
        glDisableVertexAttribArray(GLuint(mesh.vertexAttribute))
        glDisableVertexAttribArray(GLuint(mesh.colorAttribute))
    }
    
}

// MARK: OpenGL Helper

extension Renderer {
    
    func CompileShader(type: GLenum, shaderFile file: String) -> GLuint {
        
        // 1. Create the shader object
        let shader = glCreateShader(type)
        guard shader > 0 else { return 0 }
        
        // 2. Load the shader
        var source: UnsafePointer<GLchar>
        do {
            let encoding = String.Encoding.utf8.rawValue
            source = try NSString(contentsOfFile: file, encoding: encoding).utf8String!
        } catch {
            print("Failed to load vertex shader")
            return 0
        }
        
        var castSource: UnsafePointer<GLchar>? = UnsafePointer<GLchar>(source)
        glShaderSource(shader, 1, &castSource, nil)

        
        // 3. Compile the shader
        glCompileShader(shader)
        
        // 4. Check compile status
        var compiled: GLint = 0
        glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &compiled)
        
        guard compiled > 0 else {
            var infoLen: GLint = 0
            glGetShaderiv(shader, GLenum(GL_INFO_LOG_LENGTH), &infoLen)
            
            if infoLen > 1 {
                var infoLog = [GLchar](repeating: 0, count: Int(infoLen))
                glGetShaderInfoLog(shader, infoLen, nil, &infoLog)
                fatalError(String(cString: infoLog))
            }
            
            glDeleteShader(shader)
            return 0
        }
        
        return shader
    }
    
    func isProgramLinked(_ program: GLuint) -> Bool {
        var linked: GLint = 0
        glGetProgramiv(program, GLenum(GL_LINK_STATUS), &linked)
        
        if linked > 0 {
            var infoLen: GLint = 0
            glGetProgramiv(program, GLenum(GL_INFO_LOG_LENGTH), &infoLen)
            
            if infoLen > 1 {
                var infoLog = [GLchar](repeating: 0, count: Int(infoLen))
                glGetProgramInfoLog(program, infoLen, nil, &infoLog)
                fatalError(String(cString: infoLog))
            }
            
            glDeleteProgram(program)
            return false
        }
        
        return true
    }
    
    func createProgram(program: inout GLuint, vertexShader: GLuint, fragmentShader: GLuint) {
        // 1. Create program for the object
        program = glCreateProgram()
        assert(program != 0, "Failed to create program")
        glAttachShader(program, vertexShader)
        glAttachShader(program, fragmentShader)
        
        // 2. Link the shader program
        glLinkProgram(program)
        assert(isProgramLinked(program), "Failed to link program")
    }
    
    func getAttributeLoction(program: inout GLuint, vertexAttribute: inout GLint, colorAttribute: inout GLint) {
        // 3. Get the location of our attribute so we can bind data to them later
        vertexAttribute = glGetAttribLocation(program, "aVertex")
        assert(vertexAttribute != -1, "glGetAttribLocation failed for aVertex")
        
        colorAttribute = glGetAttribLocation(program, "aColor")
        assert(colorAttribute != -1, "glGetAttribLocation failed for aColor")
    }
    
    func getUniforms(program: inout GLuint, mvpMatrix: inout GLint, positionUniform: inout GLint) {
        // 4. After linking, fetch reference to the uniforms in our shader
        mvpMatrix = glGetUniformLocation(program, "uMVP")
        positionUniform = glGetUniformLocation(program, "uPosition")
        assert(mvpMatrix != -1 && positionUniform != -1, "Error fetching uniform values for shader")
    }
    
    func createMeshData(mesh: [GLfloat], buffer: inout GLuint) {
        glGenBuffers(1, &buffer)
        assert(buffer != 0, "glGenBuffers failed for buffer")
        
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), buffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER),
                     MemoryLayout<GLfloat>.stride * mesh.count,
                     mesh,
                     GLenum(GL_STATIC_DRAW))
    }
    
}
