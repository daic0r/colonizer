#version 410

layout(location=0) in vec2 vertexPos;
// per instance/particle
layout(location=1) in vec3 vertTranslation;
layout(location=2) in float vertZRotation;
layout(location=3) in float vertScale;
layout(location=4) in vec4 texOffsets;
layout(location=5) in float blendFactor;

out vec2 texCoords1;
out vec2 texCoords2;
out float outBlendFactor;


// per frame
uniform mat4 viewMatrix;
uniform mat4 projectionMatrix;
uniform vec2 cellDims;

mat4 translate(vec3 vec) {
    mat4 trans = mat4(1.0, 0.0, 0.0, 0.0,
                      0.0, 1.0, 0.0, 0.0,
                      0.0, 0.0, 1.0, 0.0,
                      vec.x, vec.y, vec.z, 1.0);
    return trans;
}

mat4 rotateX(float rad) {
    mat4 rot = mat4(1.0, 0.0, 0.0, 0.0,
                    0.0, cos(rad), -sin(rad), 0.0,
                    0.0, sin(rad), cos(rad), 0.0,
                    0.0, 0.0, 0.0, 1.0);
    return rot;
}

mat4 rotateY(float rad) {
    mat4 rot = mat4(cos(rad), 0.0, sin(rad), 0.0,
                    0.0, 1.0, 0.0, 0.0,
                    -sin(rad), 0.0, cos(rad), 0.0,
                    0.0, 0.0, 0.0, 1.0);
    return rot;
}

mat4 rotateZ(float rad) {
    mat4 rot = mat4(cos(rad), -sin(rad), 0.0, 0.0,
                    sin(rad), cos(rad), 0.0, 0.0,
                    0.0, 0.0, 1.0, 0.0,
                    0.0, 0.0, 0.0, 1.0);
    return rot;
}

mat4 scale(float x, float y, float z) {
    mat4 scl = mat4(x, 0.0, 0.0, 0.0,
                    0.0, y, 0.0, 0.0,
                    0.0, 0.0, z, 0.0,
                    0.0, 0.0, 0.0, 1.0);
    return scl;
}

void main(void) {
    mat4 modelView = translate(vertTranslation);
    for (int row = 0; row < 3; ++row) {
        for (int col = 0; col < 3; ++col) {
            modelView[col][row] = viewMatrix[row][col];
        }
    }
    modelView = modelView * scale(vertScale, vertScale, vertScale) * rotateZ(vertZRotation);
    modelView = viewMatrix * modelView;
    
    vec2 texCoord = vertexPos + vec2(0.5, 0.5);
    vec2 texOffset1 = texOffsets.xy;
    vec2 texOffset2 = texOffsets.zw;
    texCoords1 = vec2(texOffset1.x + (texCoord.x * cellDims.x), texOffset1.y - (texCoord.y * cellDims.y));
    texCoords2 = vec2(texOffset2.x + (texCoord.x * cellDims.x), texOffset2.y - (texCoord.y * cellDims.y));
    outBlendFactor = blendFactor;
    gl_Position = projectionMatrix * modelView * vec4(vertexPos.x, vertexPos.y, 0.0, 1.0);
}
