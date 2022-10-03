#version 410

in vec4 clipSpaceCoord;
in vec2 texCoords;
in vec3 fromLightVector;
in vec3 toCameraVector;
out vec4 color;

//uniform sampler2D tex;
uniform sampler2D reflectionTexture;
uniform sampler2D refractionTexture;
uniform sampler2D dudvMap;
uniform sampler2D normalMap;
uniform sampler2D depthMap;

uniform float moveFactor;
uniform vec3 lightPos;
uniform vec3 lightColor;

const float waveStrength = 0.02;
const float shineDamper = 10.0;
const float reflectivity = 0.6;


void main(void) {
    /*
    vec2 ndcCoord = (clipSpaceCoord.xy / clipSpaceCoord.w) / 2.0 + 0.5;
    
    float near = 0.1;
    float far = 500.0;
    float depth = texture(depthMap, ndcCoord).r;
    float floorDistance = 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
    
    depth = gl_FragCoord.z;
    float waterDistance = 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
    float waterDepth = floorDistance - waterDistance;
    
    
    vec2 distortedTexCoords = texture(dudvMap, vec2(texCoords.x + moveFactor, texCoords.y)).rg * 0.1;
    distortedTexCoords = texCoords + vec2(distortedTexCoords.x, distortedTexCoords.y + moveFactor);
    
    vec2 totalDistortion = (texture(dudvMap, distortedTexCoords).rg * 2.0 - 1.0) * waveStrength;
    
    // Fix edge glitch
    //totalDistortion *= clamp(waterDepth / 20.0, 0.0, 1.0);

    vec2 reflectTexCoord = vec2(ndcCoord.x, -ndcCoord.y) + totalDistortion;
    reflectTexCoord.x = clamp(reflectTexCoord.x, 0.001, 0.999);
    reflectTexCoord.y = clamp(reflectTexCoord.y, -0.999, -0.001);
    
    vec2 refractTexCoord = clamp(ndcCoord + totalDistortion, 0.001, 0.999);

    vec4 reflectColor = texture(reflectionTexture, reflectTexCoord);
    vec4 refractColor = texture(refractionTexture, refractTexCoord);

    vec4 normalMapColor = texture(normalMap, distortedTexCoords);
    vec3 normal = vec3(normalMapColor.r * 2.0 - 1.0, normalMapColor.b * 3.0, normalMapColor.g * 2.0 - 1.0);
    normal = normalize(normal);
    
    vec3 viewVector = normalize(toCameraVector);
    float refractiveFactor = dot(viewVector, normal);
    refractiveFactor = pow(refractiveFactor, 0.5);
    
    vec3 reflectedLight = reflect(normalize(fromLightVector), normal);
    float specular = max(dot(reflectedLight, viewVector), 0.0);
    specular = pow(specular, shineDamper);
    vec3 specularHighlights = lightColor * specular * reflectivity;
    
    // Dampen effect near the edges
    //specularHighlights *= clamp(waterDepth / 5.0, 0.0, 1.0);
    
    color = mix(reflectColor, refractColor, refractiveFactor);
    color = mix(color, vec4(0.0, 0.3, 0.5, 1.0), 0.2) + vec4(specularHighlights, 0.0);
    color.a = clamp(waterDepth / 10.0, 0.0, 1.0);
    */
    color = vec4(0,0,1,1);
}
