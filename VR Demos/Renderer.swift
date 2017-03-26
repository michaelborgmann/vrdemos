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
    
    // MARK: GL variables for the cube
    let cube = Cube()
    
    var cubeVertices = [GLfloat]()
    var cubeColors = [GLfloat]()
    var cubeFoundColors = [GLfloat]()
    var cubePosition = [GLfloat]()
    
    var cubeProgram: GLuint = 0
    var cubeVertexAttribute: GLint = 0
    var cubeColorAttribute: GLint = 0
    var cubeMvpMatrix: GLint = 0
    var cubePositionUniform: GLint = 0
    var cubeVertexBuffer: GLuint = 0
    var cubeColorBuffer: GLuint = 0
    var cubeFoundColorBuffer: GLuint = 0
    
    // MARK: GL variables for the grid
    let grid = Grid()
    
    var gridPosition = [GLfloat]()
    var gridVertices = [GLfloat]()
    var gridColors = [GLfloat]()
    
    var gridProgram: GLuint = 0
    var gridVertexAttribute: GLint = 0
    var gridColorAttribute: GLint = 0
    var gridMvpMatrix: GLint = 0
    var gridPositionUniform: GLint = 0
    var gridVertexBuffer: GLuint = 0
    var gridColorBuffer: GLuint = 0
    
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
        
        /////////// CUBE
        
        // 2. Create the program object for the cube
        cubeProgram = glCreateProgram()
        assert(cubeProgram != 0, "Failed to create program")
        glAttachShader(cubeProgram, vertexShader)
        glAttachShader(cubeProgram, fragmentShader)
        
        // 3. Link the shader program
        glLinkProgram(cubeProgram)
        assert(isProgramLinked(cubeProgram), "Failed to link cubeProgram")
        
        // 4. Get the location of our attribute so we can bind data to them later
        cubeVertexAttribute = glGetAttribLocation(cubeProgram, "aVertex")
        assert(cubeVertexAttribute != -1, "glGetAttribLocation failed for aVertex")
        
        cubeColorAttribute = glGetAttribLocation(cubeProgram, "aColor")
        assert(cubeColorAttribute != -1, "glGetAttribLocation failed for aColor")
        
        // 5. After linking, fetch reference to the uniforms in our shader
        cubeMvpMatrix = glGetUniformLocation(cubeProgram, "uMVP")
        cubePositionUniform = glGetUniformLocation(cubeProgram, "uPosition")
        assert(cubeMvpMatrix != -1 && cubePositionUniform != -1, "Error fetching uniform values for shader")
        
        // 6. Initialize the vertex data for the cube mesh
        for i in 0..<cube.vertices.count {
            cubeVertices.append(GLfloat(cube.vertices[i] * cube.size))
        }
        
        glGenBuffers(1, &cubeVertexBuffer)
        assert(cubeVertexBuffer != 0, "glGenBuffers failed for vertex buffer")
        
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), cubeVertexBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER),
                     MemoryLayout<GLfloat>.stride * cubeVertices.count,
                     cubeVertices,
                     GLenum(GL_STATIC_DRAW))
    
        // 7. Initialize the color data for the cube mesh
        for i in  0..<cube.colors.count {
            cubeColors.append(GLfloat(cube.colors[i] * cube.size))
        }
        
        glGenBuffers(1, &cubeColorBuffer)
        assert(cubeColorBuffer != 0, "glGenBuffers failed for color buffer")
        
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), cubeColorBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER),
                     MemoryLayout<GLfloat>.stride * cubeColors.count,
                     cubeColors, GLenum(GL_STATIC_DRAW))
        
        // 8. Initialize the found color data for the cube mesh
        for i in 0..<cube.colors.count {
            cubeFoundColors.append(GLfloat(cube.foundColors[i] * cube.size))
        }

        glGenBuffers(1, &cubeFoundColorBuffer)
        assert(cubeFoundColorBuffer != 0, "glGenBuffers failed for color buffer")
        
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), cubeFoundColorBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER),
                     MemoryLayout<GLfloat>.stride * cubeFoundColors.count,
                     cubeColors, GLenum(GL_STATIC_DRAW))
        
        /////////// CUBE
        
        // 9. Create the program object for the grid
        gridProgram = glCreateProgram()
        assert(gridProgram != 0, "Failed to create program")
        glAttachShader(gridProgram, vertexShader)
        glAttachShader(gridProgram, gridFragmentShader)
        glLinkProgram(gridProgram)
        assert(isProgramLinked(gridProgram), "Failed to link gridProgram")
        
        // 10. Get the location of our attributes so we can bind data to them later
        gridVertexAttribute = glGetAttribLocation(gridProgram, "aVertex")
        assert(gridVertexAttribute != -1, "glGetAttribLocation failed for aVertex")
        
        gridColorAttribute = glGetAttribLocation(gridProgram, "aColor")
        assert(gridColorAttribute != -1, "glGetAttribLocation failed for aColor")
        
        // 11. After linking, fetch references to the uniforms in our shader
        gridMvpMatrix = glGetUniformLocation(gridProgram, "uMVP")
        gridPositionUniform = glGetUniformLocation(gridProgram, "uPosition")
        assert(gridMvpMatrix != -1 && gridPositionUniform != -1, "Error fetching uniform values for shader")
        
        // 12. Position grid below the camera)
        gridPosition.append(0)
        gridPosition.append(-20.0)
        gridPosition.append(0)
        
        for i in 0..<grid.vertices.count {
            gridVertices.append(GLfloat(grid.vertices[i] * grid.size))
        }
        
        glGenBuffers(1, &gridVertexBuffer)
        assert(gridVertexBuffer != 0, "glGenBuffers failed for vertex buffer")
        
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), gridVertexBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER),
                     MemoryLayout<GLfloat>.stride * gridVertices.count,
            gridVertices,
            GLenum(GL_STATIC_DRAW))
        
        // 13. Initialize the color data for the grid mesh.
        for i in  0..<grid.colors.count {
            gridColors.append(GLfloat(grid.colors[i] * grid.size))
        }
        
        glGenBuffers(1, &gridColorBuffer)
        assert(gridColorBuffer != 0, "glGenBuffers failed for color buffer")
        
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), gridColorBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER),
                     MemoryLayout<GLfloat>.stride * gridColors.count,
                     gridColors, GLenum(GL_STATIC_DRAW))
        
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
        
        let sourceCubePosition = GLKVector3Make(cubePosition[0], cubePosition[1], cubePosition[2])
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
        
        renderWithModelViewProjectionMatrix(modelViewMatrix: &modelViewProjectionMatrix.m)
    }
    
    func cardboardView(_ cardboardView: GVRCardboardView!, didFire event: GVRUserEvent) {
        
    }
    
    func cardboardView(_ cardboardView: GVRCardboardView!, shouldPauseDrawing pause: Bool) {
        
    }
    
    func spawnCube() {
        setRandomCubePosition(min: cube.minDistance, maxLimit: cube.maxDistance)
        // TODO: implement audio
    }
    
    func setRandomCubePosition(min: Double, maxLimit max: Double) {
        let distance = min + ((max - min) * drand48())
        let azimuth = drand48() *  cube.azimuthRadians
        let elevation = (2.0 * drand48() * cube.elevationRadians) - cube.elevationRadians
        
        cubePosition.append(GLfloat(-cos(elevation) * sin(azimuth) * distance))
        cubePosition.append(GLfloat(sin(elevation) * distance))
        cubePosition.append(GLfloat(-cos(elevation) * cos(azimuth) * distance))
    }
    
    func isLookingAtObject(headRotation: GLKQuaternion, sourcePosition position: GLKVector3) -> Bool {
        let sourceDirection = GLKQuaternionRotateVector3(GLKQuaternionInvert(headRotation), position)
        return Double(abs(sourceDirection.v.0)) < cube.thresholdRadians &&
               Double(abs(sourceDirection.v.1)) < cube.thresholdRadians
    }
    
    func renderWithModelViewProjectionMatrix(modelViewMatrix: inout (Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float, Float)) {
        
        // Select our shader
        glUseProgram(cubeProgram)
        
        // Set the uniform values that will be used by our shader
        glUniform3fv(cubePositionUniform, 1, cubePosition)
        
        // Set the uniform matrix values that will be used by our shader
        withUnsafeMutablePointer(to: &modelViewMatrix) {
            //glUniformMatrix4fv(cubeMvpMatrix, 1, GLboolean(false), UnsafePointer($0))
            $0.withMemoryRebound(to: GLfloat.self, capacity: MemoryLayout.size(ofValue: modelViewMatrix) , {
                glUniformMatrix4fv(cubeMvpMatrix, 1, GLboolean(false), UnsafePointer<GLfloat>($0)!)
            })
        }
        
        // Set the cube colors
        if isCubeFocues {
            glBindBuffer(GLenum(GL_ARRAY_BUFFER), cubeFoundColorBuffer)
        } else {
            glBindBuffer(GLenum(GL_ARRAY_BUFFER), cubeColorBuffer)
        }

        glVertexAttribPointer(GLuint(cubeColorAttribute), 4, GLenum(GL_FLOAT), GLboolean(GL_FALSE),
                                GLsizei(MemoryLayout<Float>.stride * 4),
                                UnsafeRawPointer(bitPattern: 0))
        glEnableVertexAttribArray(GLuint(cubeColorAttribute))
        
        // Draw our polygons
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), cubeVertexBuffer)
        glVertexAttribPointer(GLuint(cubeVertexAttribute), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE),
                              GLsizei(MemoryLayout<Float>.stride * 3),
                              UnsafeRawPointer(bitPattern: 0))
        glEnableVertexAttribArray(GLuint(cubeVertexAttribute))
        glDrawArrays(GLenum(GL_TRIANGLES), 0, GLsizei(cube.vertices.count / 3))
        glDisableVertexAttribArray(GLuint(cubeVertexAttribute))
        glDisableVertexAttribArray(GLuint(cubeColorAttribute))

        // Select our shader
        glUseProgram(gridProgram)
        
        // Set the uniform values that will be used by our shader
        glUniform3fv(gridPositionUniform, 1, gridPosition)
        
        // Set the uniform matrix values that will be used by our shader
        withUnsafeMutablePointer(to: &modelViewMatrix) {
            //glUniformMatrix4fv(cubeMvpMatrix, 1, GLboolean(false), UnsafePointer($0))
            $0.withMemoryRebound(to: GLfloat.self, capacity: MemoryLayout.size(ofValue: modelViewMatrix) , {
                glUniformMatrix4fv(gridMvpMatrix, 1, GLboolean(false), UnsafePointer<GLfloat>($0)!)
            })
        }
        
        // Set the grid colors
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), gridColorBuffer)
        glVertexAttribPointer(GLuint(gridColorAttribute), 4, GLenum(GL_FLOAT), GLboolean(GL_FALSE),
                              GLsizei(MemoryLayout<Float>.stride * 4),
                              UnsafeRawPointer(bitPattern: 0))
        glEnableVertexAttribArray(GLuint(gridColorAttribute))
        
        // Draw our polygons
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), gridVertexBuffer)
        glVertexAttribPointer(GLuint(gridVertexAttribute), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE),
                              GLsizei(MemoryLayout<Float>.stride * 3),
                              UnsafeRawPointer(bitPattern: 0))
        glEnableVertexAttribArray(GLuint(gridVertexAttribute))
        glDrawArrays(GLenum(GL_TRIANGLES), 0, GLsizei(grid.vertices.count / 3))
        glDisableVertexAttribArray(GLuint(gridVertexAttribute))
        glDisableVertexAttribArray(GLuint(gridColorAttribute))
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
}

// MARK: Vertices

struct Cube {
    
    // Vertices for uniform cube mesh centered at the origin
    let vertices = [
        // Front face
        -0.5, 0.5, 0.5,
        -0.5, -0.5, 0.5,
        0.5, 0.5, 0.5,
        -0.5, -0.5, 0.5,
        0.5, -0.5, 0.5,
        0.5, 0.5, 0.5,
    
        // Right face
        0.5, 0.5, 0.5,
        0.5, -0.5, 0.5,
        0.5, 0.5, -0.5,
        0.5, -0.5, 0.5,
        0.5, -0.5, -0.5,
        0.5, 0.5, -0.5,
        
        // Back face
        0.5, 0.5, -0.5,
        0.5, -0.5, -0.5,
        -0.5, 0.5, -0.5,
        0.5, -0.5, -0.5,
        -0.5, -0.5, -0.5,
        -0.5, 0.5, -0.5,
        
        // Left face
        -0.5, 0.5, -0.5,
        -0.5, -0.5, -0.5,
        -0.5, 0.5, 0.5,
        -0.5, -0.5, -0.5,
        -0.5, -0.5, 0.5,
        -0.5, 0.5, 0.5,
        
        // Top face
        -0.5, 0.5, -0.5,
        -0.5, 0.5, 0.5,
        0.5, 0.5, -0.5,
        -0.5, 0.5, 0.5,
        0.5, 0.5, 0.5,
        0.5, 0.5, -0.5,
        
        // Bottom face
        0.5, -0.5, -0.5,
        0.5, -0.5, 0.5,
        -0.5, -0.5, -0.5,
        0.5, -0.5, 0.5,
        -0.5, -0.5, 0.5,
        -0.5, -0.5, -0.5,
    ]
    
    // Color of the cube's six faces.
    let colors = [
        // front, green
        0.0, 0.5273, 0.2656, 1.0,
        0.0, 0.5273, 0.2656, 1.0,
        0.0, 0.5273, 0.2656, 1.0,
        0.0, 0.5273, 0.2656, 1.0,
        0.0, 0.5273, 0.2656, 1.0,
        0.0, 0.5273, 0.2656, 1.0,
    
        // right, blue
        0.0, 0.3398, 0.9023, 1.0,
        0.0, 0.3398, 0.9023, 1.0,
        0.0, 0.3398, 0.9023, 1.0,
        0.0, 0.3398, 0.9023, 1.0,
        0.0, 0.3398, 0.9023, 1.0,
        0.0, 0.3398, 0.9023, 1.0,
    
        // back, also green
        0.0, 0.5273, 0.2656, 1.0,
        0.0, 0.5273, 0.2656, 1.0,
        0.0, 0.5273, 0.2656, 1.0,
        0.0, 0.5273, 0.2656, 1.0,
        0.0, 0.5273, 0.2656, 1.0,
        0.0, 0.5273, 0.2656, 1.0,
    
        // left, also blue
        0.0, 0.3398, 0.9023, 1.0,
        0.0, 0.3398, 0.9023, 1.0,
        0.0, 0.3398, 0.9023, 1.0,
        0.0, 0.3398, 0.9023, 1.0,
        0.0, 0.3398, 0.9023, 1.0,
        0.0, 0.3398, 0.9023, 1.0,
    
        // top, red
        0.8359375, 0.17578125, 0.125, 1.0,
        0.8359375, 0.17578125, 0.125, 1.0,
        0.8359375, 0.17578125, 0.125, 1.0,
        0.8359375, 0.17578125, 0.125, 1.0,
        0.8359375, 0.17578125, 0.125, 1.0,
        0.8359375, 0.17578125, 0.125, 1.0,
    
        // bottom, also red
        0.8359375, 0.17578125, 0.125, 1.0,
        0.8359375, 0.17578125, 0.125, 1.0,
        0.8359375, 0.17578125, 0.125, 1.0,
        0.8359375, 0.17578125, 0.125, 1.0,
        0.8359375, 0.17578125, 0.125, 1.0,
        0.8359375, 0.17578125, 0.125, 1.0,
    ]
    
    // Cube color when looking at it: Yellow.
    let foundColors = [
        // front, yellow
        1.0, 0.6523, 0.0, 1.0,
        1.0, 0.6523, 0.0, 1.0,
        1.0, 0.6523, 0.0, 1.0,
        1.0, 0.6523, 0.0, 1.0,
        1.0, 0.6523, 0.0, 1.0,
        1.0, 0.6523, 0.0, 1.0,
        
        // right, yellow
        1.0, 0.6523, 0.0, 1.0,
        1.0, 0.6523, 0.0, 1.0,
        1.0, 0.6523, 0.0, 1.0,
        1.0, 0.6523, 0.0, 1.0,
        1.0, 0.6523, 0.0, 1.0,
        1.0, 0.6523, 0.0, 1.0,
        
        // back, yellow
        1.0, 0.6523, 0.0, 1.0,
        1.0, 0.6523, 0.0, 1.0,
        1.0, 0.6523, 0.0, 1.0,
        1.0, 0.6523, 0.0, 1.0,
        1.0, 0.6523, 0.0, 1.0,
        1.0, 0.6523, 0.0, 1.0,
        
        // left, yellow
        1.0, 0.6523, 0.0, 1.0,
        1.0, 0.6523, 0.0, 1.0,
        1.0, 0.6523, 0.0, 1.0,
        1.0, 0.6523, 0.0, 1.0,
        1.0, 0.6523, 0.0, 1.0,
        1.0, 0.6523, 0.0, 1.0,
        
        // top, yellow
        1.0, 0.6523, 0.0, 1.0,
        1.0, 0.6523, 0.0, 1.0,
        1.0, 0.6523, 0.0, 1.0,
        1.0, 0.6523, 0.0, 1.0,
        1.0, 0.6523, 0.0, 1.0,
        1.0, 0.6523, 0.0, 1.0,
        
        // bottom, yellow
        1.0, 0.6523, 0.0, 1.0,
        1.0, 0.6523, 0.0, 1.0,
        1.0, 0.6523, 0.0, 1.0,
        1.0, 0.6523, 0.0, 1.0,
        1.0, 0.6523, 0.0, 1.0,
        1.0, 0.6523, 0.0, 1.0,
    ]
    
    let size = 1.0
    let minDistance = 2.0
    let maxDistance = 7.0
    let azimuthRadians = 2.0 * M_PI
    let elevationRadians = 0.25 * M_PI
    let thresholdRadians = 0.5
}

struct Grid {
    
    // The grid lines on the floor are rendered procedurally and large polygons cause floating point
    // precision problems on some architectures. So we split the floor into 4 quadrants.
    let vertices = [
        // +X, +Z quadrant
        200.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        0.0, 0.0, 200.0,
        200.0, 0.0, 0.0,
        0.0, 0.0, 200.0,
        200.0, 0.0, 200.0,
        
        // -X, +Z quadrant
        0.0, 0.0, 0.0,
        -200.0, 0.0, 0.0,
        -200.0, 0.0, 200.0,
        0.0, 0.0, 0.0,
        -200.0, 0.0, 200.0,
        0.0, 0.0, 200.0,
        
        // +X, -Z quadrant
        200.0, 0.0, -200.0,
        0.0, 0.0, -200.0,
        0.0, 0.0, 0.0,
        200.0, 0.0, -200.0,
        0.0, 0.0, 0.0,
        200.0, 0.0, 0.0,
        
        // -X, -Z quadrant
        0.0, 0.0, -200.0,
        -200.0, 0.0, -200.0,
        -200.0, 0.0, 0.0,
        0.0, 0.0, -200.0,
        -200.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
    ]
    
    let colors = [
        0.0, 0.3398, 0.9023, 1.0,
        0.0, 0.3398, 0.9023, 1.0,
        0.0, 0.3398, 0.9023, 1.0,
        0.0, 0.3398, 0.9023, 1.0,
        0.0, 0.3398, 0.9023, 1.0,
        0.0, 0.3398, 0.9023, 1.0,
        0.0, 0.3398, 0.9023, 1.0,
        0.0, 0.3398, 0.9023, 1.0,
        0.0, 0.3398, 0.9023, 1.0,
        0.0, 0.3398, 0.9023, 1.0,
        0.0, 0.3398, 0.9023, 1.0,
        0.0, 0.3398, 0.9023, 1.0,
        0.0, 0.3398, 0.9023, 1.0,
        0.0, 0.3398, 0.9023, 1.0,
        0.0, 0.3398, 0.9023, 1.0,
        0.0, 0.3398, 0.9023, 1.0,
        0.0, 0.3398, 0.9023, 1.0,
        0.0, 0.3398, 0.9023, 1.0,
        0.0, 0.3398, 0.9023, 1.0,
        0.0, 0.3398, 0.9023, 1.0,
        0.0, 0.3398, 0.9023, 1.0,
        0.0, 0.3398, 0.9023, 1.0,
        0.0, 0.3398, 0.9023, 1.0,
        0.0, 0.3398, 0.9023, 1.0,
    ]
    
    let size = 1.0

}
