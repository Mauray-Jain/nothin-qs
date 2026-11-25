#version 440
// Halftone: the source sampled once per grid cell, drawn as a dot whose area
// follows the cell's brightness. ink dots on paper, or dots in the image's
// own colours when colorMode is 1.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 resolution; // item size in pixels
    float dotSize;   // grid cell in pixels
    float light;     // 0..1, 0.5 leaves brightness as is
    vec4 ink;
    vec4 paper;
    float colorMode; // 0 = ink, 1 = the cell's colour
};

layout(binding = 1) uniform sampler2D source;

void main() {
    vec2 px = qt_TexCoord0 * resolution;
    vec2 centre = (floor(px / dotSize) + 0.5) * dotSize;
    vec3 c = texture(source, centre / resolution).rgb;
    float lum = clamp(dot(c, vec3(0.299, 0.587, 0.114)) + light - 0.5, 0.0, 1.0);
    float r = 0.5 * dotSize * sqrt(lum);
    float m = 1.0 - smoothstep(r - 0.75, r + 0.75, length(px - centre));
    vec4 fill = mix(ink, vec4(c, 1.0), colorMode);
    fragColor = mix(paper, fill, m) * qt_Opacity;
}
