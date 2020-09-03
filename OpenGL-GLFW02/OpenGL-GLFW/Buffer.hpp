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
#include <iostream>

namespace gl {
using namespace std;

class Buffer {
  public:
	Buffer(const string &imageName);
	~Buffer();

	void Draw() const;

  private:
	GLuint VBO, VAO, EBO, texture;
};
}  // namespace gl

#endif /* Buffer_hpp */

