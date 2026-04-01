#version 330 core
out vec4 FragColor;
in vec2 TexCoord;

uniform vec2 mousePos;
uniform sampler2D prevBuffer;
uniform vec2 resolution;
uniform bool mouseDown;

vec3 emptyColor = vec3(0.0, 0.0, 0.0);
vec3 waterColor = vec3(0.0, 0.0, 0.8);
vec3 solidColor = vec3(1.0);

bool isWater(vec4 color) {
    return all(equal(color.rgb, waterColor));
}

bool isEmpty(vec4 color) {
    return all(equal(color.rgb, emptyColor));
}

bool isSolid(vec4 color)
{
    return all(equal(color.rgb, solidColor));
}

bool isSupport(vec4 color) {
    return isWater(color) || isSolid(color);
}

void main() {
    vec2 pixelSize = 1.0 / resolution;
    vec4 current = texture(prevBuffer, TexCoord);
    vec2 mouseLoc = mousePos / resolution;

    // Boundry
    bool atBottom = (TexCoord.y < pixelSize.y);
    bool atLeft   = (TexCoord.x < pixelSize.x);
    bool atRight  = (TexCoord.x > 1.0 - pixelSize.x);

    if(atBottom || atLeft || atRight) {FragColor = vec4(solidColor, 1.0); return;}

    // Sampling
    vec4 above  = texture(prevBuffer, TexCoord + vec2(0.0, pixelSize.y));
    vec4 below  = texture(prevBuffer, TexCoord + vec2(0.0, -pixelSize.y));
    vec4 left   = texture(prevBuffer, TexCoord + vec2(-pixelSize.x, 0.0));
    vec4 right  = texture(prevBuffer, TexCoord + vec2(pixelSize.x, 0.0));

    vec4 bRight = texture(prevBuffer, TexCoord + vec2(pixelSize.x, -pixelSize.y));
    vec4 bLeft  = texture(prevBuffer, TexCoord + vec2(-pixelSize.x, -pixelSize.y));
    vec4 left2  = texture(prevBuffer, TexCoord + vec2(2.0 * -pixelSize.x, 0.0));

    // Brush Logic
    float aspect = resolution.x / resolution.y;
    vec2 distVec = (TexCoord - mouseLoc);
    distVec.x *= aspect;
    if (mouseDown && length(distVec) < 0.02) {
        FragColor = vec4(waterColor, 1.0);
        return;
    }

    if (isEmpty(current)) {
        bool fromAbove = isWater(above);
        // FIX: Water can move sideways if the pixel below is Water OR Solid ground
        bool fromRight = isWater(right) && isSupport(bRight);
        bool fromLeft  = isWater(left) && isSupport(bLeft) && isSupport(left2);

        if (fromAbove || fromRight || fromLeft) {
            FragColor = vec4(waterColor, 1.0);
            return;
        }
    }

    if (isWater(current)) {
        // Fall down if space below is empty
        bool canFall = !isSupport(below);

        // Move sideways only if we aren't falling and a side is empty
        bool canMoveSide = !canFall && (!isSupport(left) || !isSupport(right));

        if (canFall || canMoveSide) {
            FragColor = vec4(emptyColor, 1.0);
            return;
        }
    }

    FragColor = current;
}