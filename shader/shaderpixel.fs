#version 330 core
out vec4 FragColor;
in vec2 TexCoord;

void main() {
    // CONFIGURATION
    float pixelScale = 128.0;

    // 1. Quantize the UV coordinates
    vec2 pixelatedUV = floor(TexCoord * pixelScale) / pixelScale;

    // 2. Generate a color based on the "Pixel" coordinate
    // This creates a simple grid pattern for testing:
    float r = pixelatedUV.x;
    float g = pixelatedUV.y;
    float b = 0.5 + 0.5 * sin(pixelatedUV.x * 10.0);

    FragColor = vec4(r, g, b, 1.0);
}