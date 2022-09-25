//
//  Frustum.h
//  MetalLoadOBJ
//
//  Created by king on 2022/9/23.
//

#ifndef Frustum_h
#define Frustum_h

#include <glm/glm.hpp>

#include "Camera.h"

struct Plan {
    glm::vec3 normal = {0.f, 1.f, 0.f};  // unit vector
    float distance = 0.f;                // Distance with origin

    Plan() = default;

    Plan(const glm::vec3 &p1, const glm::vec3 &norm)
        : normal(glm::normalize(norm))
        , distance(glm::dot(normal, p1)) {}

    float getSignedDistanceToPlan(const glm::vec3 &point) const {
        return glm::dot(normal, point) - distance;
    }
};

struct Frustum {
    Plan topFace;
    Plan bottomFace;

    Plan rightFace;
    Plan leftFace;

    Plan farFace;
    Plan nearFace;
};

Frustum createFrustumFromCamera(const Camera &cam, float aspect, float fovY, float zNear, float zFar) {
    Frustum frustum;
    const float halfVSide = zFar * tanf(fovY * .5f);
    const float halfHSide = halfVSide * aspect;
    const glm::vec3 frontMultFar = zFar * cam.Front;

    frustum.nearFace = {cam.Position + zNear * cam.Front, cam.Front};
    frustum.farFace = {cam.Position + frontMultFar, -cam.Front};
    frustum.rightFace = {cam.Position, glm::cross(cam.Up, frontMultFar + cam.Right * halfHSide)};
    frustum.leftFace = {cam.Position, glm::cross(frontMultFar - cam.Right * halfHSide, cam.Up)};
    frustum.topFace = {cam.Position, glm::cross(cam.Right, frontMultFar - cam.Up * halfVSide)};
    frustum.bottomFace = {cam.Position, glm::cross(frontMultFar + cam.Up * halfVSide, cam.Right)};

    return frustum;
}
#endif /* Frustum_h */

