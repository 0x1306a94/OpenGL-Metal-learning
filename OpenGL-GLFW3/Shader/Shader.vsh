#version 410 core

layout (location = 0) in vec4 position;
layout (location = 1) in vec3 color;

out vec3 ourColor;

//uniform mat4 transformto;
uniform mat4 rotate;
//uniform mat4 transformback;
uniform bool transformed;

void main() {
	if (transformed) {
//		gl_Position =  transformback * rotate * transformto * position;
		gl_Position = rotate * position;
	} else {
		gl_Position = position;
	}
	ourColor = color;//vec3(0.5,0.6,0.8);
}

