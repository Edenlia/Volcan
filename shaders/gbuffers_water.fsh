#version 120

uniform sampler2D lightmap;
uniform sampler2D texture;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;
varying float blockId;

bool isBlockId(float entityId, int blockId) {
	return abs(entityId - float(blockId)) < 0.03; // rounding error
}

/* DRAWBUFFERS:0 */
void main() {
	// if not water, just draw the texture
	if(!isBlockId(blockId, 10091)) {
		vec4 color = texture2D(texture, texcoord) * glcolor;
		color *= texture2D(lightmap, lmcoord);
		gl_FragData[0] = color;
		return;
	}

	gl_FragData[0] = vec4(vec3(0.1, 0.2, 0.4), 0.9); //gcolor
}