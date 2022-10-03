#version 410

in vec2 vertexPos;

out vec2 texCoord;
out vec4 clipValues;
out vec2 cornerCirclePos[4];
//out float outCornerRadius;
out vec2 normalizedCoords;

uniform vec2 position;
uniform vec2 scaleFactors;

uniform vec2 alignOffset;
uniform vec2 minPoint;
uniform vec2 maxPoint;
uniform vec4 minMaxTexCoords;
uniform bool isTextured;
uniform float aspectRatio;
uniform float cornerRadius;


mat4 translate(vec3 vec) {
    mat4 trans = mat4(1.0, 0.0, 0.0, 0.0,
                      0.0, 1.0, 0.0, 0.0,
                      0.0, 0.0, 1.0, 0.0,
                      vec.x, vec.y, vec.z, 1.0);
    return trans;
}

mat4 scale(float x, float y, float z) {
    mat4 scl = mat4(x, 0.0, 0.0, 0.0,
                    0.0, y, 0.0, 0.0,
                    0.0, 0.0, z, 0.0,
                    0.0, 0.0, 0.0, 1.0);
    return scl;
}

void main() {
    if (isTextured) {
        if (vertexPos == vec2(0, 0))
            texCoord = minMaxTexCoords.xy;
        else
        if (vertexPos == vec2(1, 0))
            texCoord = minMaxTexCoords.zy;
        else
        if (vertexPos == vec2(0, 1))
            texCoord = minMaxTexCoords.xw;
        else
        if (vertexPos == vec2(1, 1))
            texCoord = minMaxTexCoords.zw;
    }

    
    // Clipping plane calculations work with values centered around 0, distance from origin is always positive
    // So here we center the range [min, max] around zero and then offset the min and max points by this value
    // Finally absolute value is taken to get the positive distance
    float xShift = (maxPoint.x + minPoint.x) / 2;
    float yShift = (maxPoint.y + minPoint.y) / 2;
    vec3 planeLeft = vec3( 1.0, 0.0, abs(minPoint.x - xShift));
    vec3 planeRight = vec3( -1.0, 0.0, abs(maxPoint.x - xShift));
    vec3 planeBottom = vec3( 0.0, 1.0, abs(minPoint.y - yShift));
    vec3 planeTop = vec3( 0.0, -1.0, abs(maxPoint.y - yShift));
    
    mat4 modelMatrix = translate(vec3(position, 0.0)) * scale(scaleFactors.x, scaleFactors.y, 1.0);
    
    vec2 tempVertex = vertexPos + alignOffset;
    
    vec4 outVertex = modelMatrix * vec4( tempVertex.xy, 1.0, 1.0 );

    // Calculate the circles outside of which we need to clip for the rounded corners
    cornerCirclePos[0] = vec2(0.0, 0.0);
    cornerCirclePos[1] = vec2(0.0, 1.0);
    cornerCirclePos[2] = vec2(1.0, 0.0);
    cornerCirclePos[3] = vec2(1.0, 1.0);

    for (int i = 0; i < 4; ++i) {
        cornerCirclePos[i] += alignOffset;
        vec4 transf = modelMatrix * vec4(cornerCirclePos[i].xy, 1.0, 1.0);
        cornerCirclePos[i] = transf.xy;
    }

    float fScaledRadius = cornerRadius * aspectRatio;
    cornerCirclePos[0] += vec2(cornerRadius, fScaledRadius);
    cornerCirclePos[1] += vec2(cornerRadius, -(fScaledRadius));
    cornerCirclePos[2] += vec2(-cornerRadius, fScaledRadius);
    cornerCirclePos[3] += vec2(-cornerRadius, -(fScaledRadius));
    //////////////////////////////////////////////////////////////////////////////////////

    // In order to test whether the vertex must be clipped, we move it to its final position (rotation not honored,
    // must still be taken care of) and then also center the values around zero by subtracting the shift values
    // calculated above
    vec3 transformedAndCentered = vec3(outVertex.xy - vec2(xShift, yShift), 1.0);
    clipValues[0] = dot(transformedAndCentered, planeLeft);
    clipValues[1] = dot(transformedAndCentered, planeRight);
    clipValues[2] = dot(transformedAndCentered, planeBottom);
    clipValues[3] = dot(transformedAndCentered, planeTop);

//    outCornerRadius = cornerRadius;
    normalizedCoords = outVertex.xy;
    
    gl_Position = outVertex;
}
