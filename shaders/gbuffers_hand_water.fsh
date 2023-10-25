#version 120

uniform sampler2D lightmap;
uniform sampler2D texture;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
varying vec3 viewNormal;
varying vec4 worldPosition;

/* DRAWBUFFERS:02 */
void main() {
	vec4 color = texture2D(texture, texcoord) * glcolor;
	color *= texture2D(lightmap, lmcoord);

	vec3 normal = normalize(viewNormal);

	gl_FragData[0] = color; //gcolor
	gl_FragData[1] = vec4(normal * 0.5 + 0.5, 1.0); //gnormal
//	gl_FragData[1] = vec4(999, 0, 0, 1);
}