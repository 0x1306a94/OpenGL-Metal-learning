//
//  Shader.cpp
//  OpenGL-GLFW
//
//  Created by king on 2020/9/2.
//  Copyright © 2020 0x1306a94. All rights reserved.
//

#include "Shader.hpp"

#include <fstream>
#include <sstream>

using namespace std;

namespace gl {
Shader::Shader(const string &shaderFileName) {
	const string vertexSource   = parseShaderString("./Shader/" + shaderFileName + ".vsh");
	const string fragmentSource = parseShaderString("./Shader/" + shaderFileName + ".fsh");

	vs = compileShader(GL_VERTEX_SHADER, vertexSource);
	fs = compileShader(GL_FRAGMENT_SHADER, fragmentSource);
}

Shader::~Shader() {
	glDeleteShader(vs);
	glDeleteShader(fs);
}

const string Shader::parseShaderString(const string &filePath) {
	ifstream in(filePath);
	stringstream buffer;
	in.exceptions(ifstream::failbit | ifstream::badbit);
	try {
		buffer << in.rdbuf();
	} catch (exception const &e) {
		cout << "parseShaderString error: " << e.what() << endl;
	}
	return buffer.str();
}

GLuint Shader::compileShader(GLenum type, const string &source) {
	GLuint id       = glCreateShader(type);
	const char *src = source.c_str();
	glShaderSource(id, 1, &src, NULL);
	glCompileShader(id);

	GLint result;
	glGetShaderiv(id, GL_COMPILE_STATUS, &result);
	if (result == GL_FALSE) {
		GLint length;
		glGetShaderiv(id, GL_INFO_LOG_LENGTH, &length);
		char *message = (char *)alloca(length * sizeof(char));
		glGetShaderInfoLog(id, length, &length, message);
		cout << "Faild to compile " << ((type == GL_VERTEX_SHADER) ? "vertex" : "fragment") << " shader!" << endl;
		cout << message << endl;
		glDeleteShader(id);
		return 0;
	}
	return id;
}
}  // namespace gl

