//
//  Shader.hpp
//  OpenGL-GLFW
//
//  Created by king on 2020/9/2.
//  Copyright © 2020 0x1306a94. All rights reserved.
//

#ifndef Shader_hpp
#define Shader_hpp

#include <GL/glew.h>
#include <iostream>

namespace gl {

using namespace std;

class Shader {

  public:
    Shader(const string &shaderFileName);
    ~Shader();

    GLuint getVS() const { return vs; };
    GLuint getFS() const { return fs; };

  private:
    GLuint vs;  // 顶点
    GLuint fs;  // 片段
    const string parseShaderString(const string &filePath);
    GLuint compileShader(GLenum type, const string &source);
};
}  // namespace gl

#endif /* Shader_hpp */

