#version 140

in vec2 vertexPos;
in vec2 texCoord;

out vec2 outTexCoord;
out vec4 clipValues;
//out float gl_ClipDistance[4];

uniform float rotation;
uniform vec2 position;
uniform vec2 minPoint;
uniform vec2 maxPoint;

mat4 translate(vec3 vec) {
    mat4 trans = mat4(1.0, 0.0, 0.0, 0.0,
                      0.0, 1.0, 0.0, 0.0,
                      0.0, 0.0, 1.0, 0.0,
                      vec.x, vec.y, vec.z, 1.0);
    return trans;
}

mat4 rotateZ(float rad) {
    mat4 rot = mat4(cos(rad), -sin(rad), 0.0, 0.0,
                    sin(rad), cos(rad), 0.0, 0.0,
                    0.0, 0.0, 1.0, 0.0,
                    0.0, 0.0, 0.0, 1.0);
    return rot;
}

void main() {
    outTexCoord = texCoord;

    // Clipping plane calculations work with values centered around 0, distance from origin is always positive
    // So here we center the range [min, max] around zero and then offset the min and max points by this value
    // Finally absolute value is taken to get the positive distance
    float xShift = (maxPoint.x + minPoint.x) / 2;
    float yShift = (maxPoint.y + minPoint.y) / 2;
    // The plane equations, z is the unsigned distance D from the origin
    vec3 planeLeft = vec3( 1.0, 0.0, abs(minPoint.x - xShift));
    vec3 planeRight = vec3( -1.0, 0.0, abs(maxPoint.x - xShift));
    vec3 planeBottom = vec3( 0.0, 1.0, abs(minPoint.y - yShift));
    vec3 planeTop = vec3( 0.0, -1.0, abs(maxPoint.y - yShift));

    mat4 modelMatrix = translate(vec3(position, 0.0));
    modelMatrix = modelMatrix * rotateZ(rotation);
    
    vec4 outVertex = modelMatrix * vec4( vertexPos.x, vertexPos.y, 1.0, 1.0 );

    // In order to test whether the vertex must be clipped, we move it to its final position (rotation not honored,
    // must still be taken care of) and then also center the values around zero by subtracting the shift values
    // calculated above
    // 30.12.2020: gl_ClipDistance leads to weird effects on Windows, so I'm resorting to
    // my own array and use discard in the fragment shader instead
    vec3 transformedAndCentered = vec3(outVertex.xy - vec2(xShift, yShift), 1.0);
    //gl_ClipDistance[0] = dot(transformedAndCentered, planeLeft);
    //gl_ClipDistance[1] = dot(transformedAndCentered, planeRight);
    //gl_ClipDistance[2] = dot(transformedAndCentered, planeBottom);
    //gl_ClipDistance[3] = dot(transformedAndCentered, planeTop);
    clipValues[0] = dot(transformedAndCentered, planeLeft);
    clipValues[1] = dot(transformedAndCentered, planeRight);
    clipValues[2] = dot(transformedAndCentered, planeBottom);
    clipValues[3] = dot(transformedAndCentered, planeTop);
    gl_Position = outVertex;
}
