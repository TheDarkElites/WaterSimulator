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
vec2 pixelSize = 1.0 / resolution;

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

vec4 getColor(int x, int y)
{
    return texture(prevBuffer, TexCoord + vec2(x * pixelSize.x, y * pixelSize.y));
}

void main() {
    vec4 current = texture(prevBuffer, TexCoord);
    vec2 mouseLoc = mousePos / resolution;

    // Boundry
    bool atBottom = (TexCoord.y < pixelSize.y);
    bool atLeft   = (TexCoord.x < pixelSize.x);
    bool atRight  = (TexCoord.x > 1.0 - pixelSize.x);

    if(atBottom || atLeft || atRight) {FragColor = vec4(solidColor, 1.0); return;}

    // Brush Logic
    float aspect = resolution.x / resolution.y;
    vec2 distVec = (TexCoord - mouseLoc);
    distVec.x *= aspect;
    if (mouseDown && length(distVec) < 0.02) {
        FragColor = vec4(waterColor, 1.0);
        return;
    }

    if (isEmpty(current)) {
        bool fromAbove = isWater(getColor(0,1));
        bool fromRight = isWater(getColor(1,0)) && isSupport(getColor(1,-1));
        bool fromLeft  = isWater(getColor(-1,0)) && isSupport(getColor(-1,-1)) && isSupport(getColor(-2,0));

        if (fromAbove || fromRight || fromLeft) {
            FragColor = vec4(waterColor, 1.0);
            return;
        }
    }

    if (isWater(current)) {
        bool canMoveLeft = !isWater(getColor(-1,1)) && !isSupport(getColor(-1,0));
        bool canMoveRight = !isWater(getColor(1,1)) && (!isWater(getColor(2,0)) || !isSupport(getColor(2,-1))) && !isSupport(getColor(1,0));
        if (!isSupport(getColor(0,-1)) || canMoveLeft || canMoveRight) {
            FragColor = vec4(emptyColor, 1.0);
            return;
        }
    }

    FragColor = current;
}

//Flow Order
//1. Top
//2. Top getColor(1,0)
//3. Top getColor(-1,0)
//4. getColor(1,0)
//5. getColor(-1,0)