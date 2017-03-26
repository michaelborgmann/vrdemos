#version 100

uniform mat4 uMVP;
uniform vec3 uPosition;
attribute vec3 aVertex;
attribute vec4 aColor;
varying vec4 vColor;
varying vec3 vGrid;
void main(void) {
    vGrid = aVertex + uPosition;
    vec4 pos = vec4(vGrid, 1.0);
    vColor = aColor;
    gl_Position = uMVP * pos;
}
