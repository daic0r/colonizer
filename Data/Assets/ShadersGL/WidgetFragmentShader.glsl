#version 410

in vec2 texCoord;
in vec2 cornerCirclePos[4];
//in float cornerRadius;
in vec2 normalizedCoords;

out vec4 fragColor;
in vec4 clipValues;

uniform vec4 color;
uniform vec4 foregroundColor;
uniform bool isMouseOver;
uniform sampler2D imageTexture;
uniform bool isTextured;
uniform float aspectRatio;
uniform vec4 borderColor;
uniform float borderThickness;
uniform float cornerRadius;

void main() {
    for (int i = 0; i < 4; ++i)
        if (clipValues[i] < 0.0)
            discard;

    vec4 useColor;// = isTextured ? texture(imageTexture, texCoord) : color;
//    float borderThickness = .005;
//    vec4 borderColor = vec4(1.0,0.0,0.0,1.0);
    bool bBorder = false;
    for (int i = 0; i < 4; ++i) {
        vec2 dir = normalizedCoords - cornerCirclePos[i];
        dir.y /= aspectRatio;
        if (length(dir) > cornerRadius) {
            if (i == 0) {
                if (dir.x < 0.0 && dir.y < 0.0)
                    discard;
            } else
            if (i == 1) {
                if (dir.x < 0.0 && dir.y > 0.0)
                    discard;
            } else
            if (i == 2) {
                if (dir.x > 0.0 && dir.y < 0.0)
                    discard;
            } else
            if (i == 3) {
                if (dir.x > 0.0 && dir.y > 0.0)
                    discard;
            }
        } else if (length(dir) <= cornerRadius && length(dir) > cornerRadius-borderThickness) {
            if (i == 0) {
                if (dir.x < 0.0 && dir.y < 0.0) {
                    useColor = borderColor;
                    bBorder = true;
                }
            } else
            if (i == 1) {
                if (dir.x < 0.0 && dir.y > 0.0) {
                    useColor = borderColor;
                    bBorder = true;
                }
            } else
            if (i == 2) {
                if (dir.x > 0.0 && dir.y < 0.0) {
                    useColor = borderColor;
                    bBorder = true;
                }
            } else
            if (i == 3) {
                if (dir.x > 0.0 && dir.y > 0.0) {
                    useColor = borderColor;
                    bBorder = true;
                }
            }
        }
    }

    if (!bBorder) {
        vec4 texColor = texture(imageTexture, texCoord);
        if (isTextured && foregroundColor.a == -1.0) {
            useColor = texColor;
        }
        else
        if (isTextured && texColor.a >= 0.0) {
            useColor = mix(texColor, foregroundColor, texColor.a);
        } else {
            useColor = color;
        }

        float fStepFunc = 1.0;
        if (borderThickness > 0.0) {
            fStepFunc = step(cornerCirclePos[0].x - cornerRadius + borderThickness, normalizedCoords.x);
            fStepFunc += (1.0 - step(cornerCirclePos[2].x + cornerRadius - borderThickness, normalizedCoords.x));
            fStepFunc += step(cornerCirclePos[0].y - (cornerRadius * aspectRatio) + borderThickness, normalizedCoords.y);
            fStepFunc += (1.0 - step(cornerCirclePos[1].y + (cornerRadius * aspectRatio) - borderThickness, normalizedCoords.y));
            fStepFunc -= 3.0;
        }
        useColor = mix(borderColor, useColor, fStepFunc);
    //fStepFuncX = clamp(fStepFuncX, 0.0, 1.0);
    }

//    useColor = (fStepFuncX * useColor) + vec4(((1 - fStepFuncX) * borderColor), (1 - fStepFuncX) * useColor.a);
    fragColor = isMouseOver ? mix(useColor, vec4(1.0, 0.0, 0.0, 0.8), 0.8) : useColor;
}