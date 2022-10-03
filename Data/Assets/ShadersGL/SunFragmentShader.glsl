#version 140

uniform vec3 sunColor;
uniform vec2 viewport;

in vec2 xy;
in float radius;
out vec4 fragmentColor;

void main() {
	vec2 radNormalized = radius / viewport;  // (0.0244140625, 0.03255)
	vec2 frag = vec2(gl_FragCoord.x, gl_FragCoord.y);
	vec2 fragNormalized = (frag - .5) / viewport;
	vec2 dist = (fragNormalized - xy);
    fragmentColor = vec4(sunColor, 1.0 - smoothstep(0.0, radNormalized.x, length(dist)));
}
