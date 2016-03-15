#pragma once

#include <Behaviour.h>
#include <Input\Keyboard.h>
#include <Math\Math.h>
#include <GameObject.h>
#include <Transform.h>

class PlayerController : public LL3D::Behaviour {
public:
  std::unique_ptr<Component> Clone() override {
    return std::unique_ptr<Component>(new PlayerController(*this));
  }

  void Update() override {
    auto h = LL3D::Input::Keyboard::GetAxis(LL3D::Input::Keyboard::Horizontal);
    auto v = LL3D::Input::Keyboard::GetAxis(LL3D::Input::Keyboard::Vertical);
    auto p = GetGameObject()->GetComponent<LL3D::Transform>()->GetWorldPosition();
    p.x += h;
    p.z += v;
    GetGameObject()->GetComponent<LL3D::Transform>()->SetWorldPosition(p);
  }
};