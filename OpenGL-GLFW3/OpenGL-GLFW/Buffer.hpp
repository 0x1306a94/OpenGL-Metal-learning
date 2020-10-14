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
	Buffer();
	~Buffer();

	void Draw(GLuint programId, bool rotate = false) const;

  private:
	GLuint VBO, VAO, EBO;
};
}  // namespace gl

#endif /* Buffer_hpp */

