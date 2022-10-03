#version 140

uniform sampler2D fontTexture;
in vec2 outTexCoord;
in vec4 clipValues;

out vec4 outColor;

uniform vec4 textColor;
uniform vec4 borderColor;

uniform float thickness;
uniform float edgeWidth;
uniform float borderWidth;
uniform float borderEdge;

uniform vec2 shadowOffset;


void main() {
    for (int i = 0; i < 4; ++i)
        if (clipValues[i] < 0.0)
            discard;

    float fDistance = 1.0 - texture(fontTexture, outTexCoord).a;
    float fAlpha = 1.0 - (edgeWidth > 0.0 ? smoothstep(thickness, thickness+edgeWidth, fDistance) : step(thickness, fDistance));
    
    float fDistance2 = 1.0 - texture(fontTexture, outTexCoord - shadowOffset).a;
    float fAlphaBorder = 1.0 - (borderEdge > 0.0 ? smoothstep(borderWidth, borderWidth+borderEdge, fDistance2) : step(borderWidth, fDistance2));
    
    float fOverallAlpha = fAlpha + (1.0 - fAlpha) * fAlphaBorder;
    
    vec4 overallColor = mix(borderColor, textColor, fAlpha / fOverallAlpha);
    
    outColor = vec4(overallColor.xyz, fOverallAlpha);
}
