//
//  Buffer.hpp
//  OpenGL-GLFW
//
//  Created by king on 2020/9/2.
//  Copyright © 2020 0x1306a94. All rights reserved.
//

#ifndef Buffer_hpp
#define Buffer_hpp

#include <GL/glew.h>
#include <glm/vec2.hpp>
#include <iostream>

#include "KeyFrameParams.hpp"

namespace gl {
using namespace std;

#define keyframesCount 6

class Buffer {
  public:
    Buffer(const glm::vec2 size);
    ~Buffer();

    void Draw(GLuint programId, float time) const;

  private:
    GLuint VBO, VAO, EBO, texture;
    glm::vec2 m_size;

    KeyFrameParams keyframes[keyframesCount];
};
}  // namespace gl

#endif /* Buffer_hpp */

