#version 410 core

layout (location = 0) in vec4 position;
layout (location = 1) in vec2 aTexCoord;

uniform mat4 mvp;

out vec2 TexCoord;

void main() {
    // 注意乘法要从右向左读
    gl_Position = mvp * position;
    TexCoord = aTexCoord;
    TexCoord.y = 1.0 - TexCoord.y;
}
