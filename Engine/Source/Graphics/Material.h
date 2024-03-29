#pragma once

#include <filesystem>
#include "Math/Math.h"

namespace LL3D {
namespace Graphics {
struct Material
{
  std::string name;

  Math::Vector3 ambient;
  Math::Vector3 diffuse;
  Math::Vector3 specular;
  Math::Vector3 emissive;    // todo
  Math::Vector3 transparent; // todo: light passing through a transparent
                             // surface is multiplied by this filter color
  float shininess = 0.f;     // specular_exponent
  float opacity = 1.f;
  float shininess_strength = 0.f; // todo: multiplier on top of specular color

  // Texture paths
  Math::Matrix texTransform = Math::Matrix::Identity;
  std::tr2::sys::path diffuseTexture;
  std::tr2::sys::path specularTexture;
  std::tr2::sys::path emissiveTexture; // todo
  std::tr2::sys::path normalTexture;
  std::tr2::sys::path lightmapTexture;   // todo
  std::tr2::sys::path reflectionTexture; // todo

  // Experimental properties !!!
  bool mirror = false;
  bool shadow = false;
};

} // namespace Graphics
} // namespace LL3D
