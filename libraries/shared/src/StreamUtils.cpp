//
//  StreamUtils.cpp
//  libraries/shared/src
//
//  Created by Andrew Meadows on 2014.
//  Copyright 2014 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//

#include <glm/gtc/type_ptr.hpp>

#include "StreamUtils.h"

const char* hex_digits = "0123456789abcdef";

void StreamUtil::dump(std::ostream& s, const QByteArray& buffer) {
    int row_size = 32;
    int i = 0;
    while (i < buffer.size()) {
        for(int j = 0; i < buffer.size() && j < row_size; ++j) {
            char byte = buffer[i];
            s << hex_digits[(byte >> 4) & 0x0f] << hex_digits[byte & 0x0f] << " ";
            ++i;
        }
        s << "\n";
    }
}

std::ostream& operator<<(std::ostream& s, const glm::vec3& v) {
    s << "<" << v.x << " " << v.y << " " << v.z << ">";
    return s;
}

std::ostream& operator<<(std::ostream& s, const glm::quat& q) {
    s << "<" << q.x << " " << q.y << " " << q.z << " " << q.w << ">";
    return s;
}

std::ostream& operator<<(std::ostream& s, const glm::mat4& m) {
    s << "[";
    for (int j = 0; j < 4; ++j) {
        s << " " << m[0][j] << " " << m[1][j] << " " << m[2][j] << " " << m[3][j] << ";";
    }
    s << "  ]";
    return s;
}

// less common utils can be enabled with DEBUG
#ifdef DEBUG

std::ostream& operator<<(std::ostream& s, const CollisionInfo& c) {
    s << "{penetration=" << c._penetration 
        << ", contactPoint=" << c._contactPoint
        << ", addedVelocity=" << c._addedVelocity
        << "}";
    return s;
}

std::ostream& operator<<(std::ostream& s, const SphereShape& sphere) {
    s << "{type='sphere', center=" << sphere.getPosition()
        << ", radius=" << sphere.getRadius()
        << "}";
    return s;
}

std::ostream& operator<<(std::ostream& s, const CapsuleShape& capsule) {
    s << "{type='capsule', center=" << capsule.getPosition()
        << ", radius=" << capsule.getRadius()
        << ", length=" << (2.f * capsule.getHalfHeight())
        << ", begin=" << capsule.getStartPoint()
        << ", end=" << capsule.getEndPoint()
        << "}";
    return s;
}

#endif // DEBUG

