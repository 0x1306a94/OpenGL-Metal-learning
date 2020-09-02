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

namespace gl {
class Buffer {
  public:
	Buffer();
	~Buffer();

	void Draw();

  private:
	GLuint VBO, VAO, EBO;
};
}  // namespace gl

#endif /* Buffer_hpp */

