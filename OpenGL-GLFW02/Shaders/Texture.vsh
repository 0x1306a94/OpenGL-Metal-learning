#version 410 core

layout (location = 0) in vec3 position;
layout (location = 1) in vec2 aTexCoord;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

out vec2 TexCoord;

void main() {
    // 注意乘法要从右向左读
    gl_Position = projection * view * model * vec4(position, 1.0);
	TexCoord = aTexCoord;
}
