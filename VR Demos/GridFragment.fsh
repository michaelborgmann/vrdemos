#version 100

#ifdef GL_ES
precision mediump float;
#endif
varying vec4 vColor;
varying vec3 vGrid;

void main() {
    float depth = gl_FragCoord.z / gl_FragCoord.w;
    if ((mod(abs(vGrid.x), 10.0) < 0.1) || (mod(abs(vGrid.z), 10.0) < 0.1)) {
        gl_FragColor = max(0.0, (90.0-depth) / 90.0) * vec4(1.0, 1.0, 1.0, 1.0) + min(1.0, depth / 90.0) * vColor;
    } else {
        gl_FragColor = vColor;
    }
}
