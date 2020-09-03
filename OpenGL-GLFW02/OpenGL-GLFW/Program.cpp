//
//  Program.cpp
//  OpenGL-GLFW
//
//  Created by king on 2020/9/2.
//  Copyright © 2020 0x1306a94. All rights reserved.
//

#include "Buffer.hpp"
#include "Program.hpp"
#include "Shader.hpp"

namespace gl {
Program::Program(std::shared_ptr<Shader> shader, std::shared_ptr<Buffer> buffer)
    : shader(shader)
    , buffer(buffer) {
	program = glCreateProgram();

	glAttachShader(program, shader->getVS());
	glAttachShader(program, shader->getFS());
	glLinkProgram(program);
	glValidateProgram(program);

	GLint result;
	glGetProgramiv(program, GL_LINK_STATUS, &result);
	if (result == GL_FALSE) {
		GLint length;
		glGetProgramiv(program, GL_INFO_LOG_LENGTH, &length);
		char *message = (char *)alloca(length * sizeof(char));
		glGetProgramInfoLog(program, length, &length, message);
	}

	glDeleteShader(shader->getVS());
	glDeleteShader(shader->getFS());
}

Program::~Program() {
	cout << this << " " << __FUNCTION__ << endl;
	glDeleteShader(program);
}

void Program::Use() {
	glUseProgram(program);
}

void Program::Draw() {
	buffer->Draw();
}
}  // namespace gl

