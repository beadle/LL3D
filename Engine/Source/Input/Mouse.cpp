#include "Mouse.h"
#include <windowsx.h>

namespace LL3D {
namespace Input {

void Mouse::ProcessMessage(UINT message, WPARAM wparam, LPARAM lparam) {
  switch (message) {
    case WM_LBUTTONDOWN:
    {
      s_pressed[Left] = true;
      s_helding_down[Left] = true;
      break;
    }
    case WM_MBUTTONDOWN:
    {
      s_pressed[Middle] = true;
      s_helding_down[Middle] = true;
      break;
    }
    case WM_RBUTTONDOWN:
    {
      s_pressed[Right] = true;
      s_helding_down[Middle] = true;
      break;;
    }
    case WM_LBUTTONUP:
    {
      s_released[Left] = true;
      s_helding_down[Left] = false;
      break;
    }
    case WM_MBUTTONUP:
    {
      s_released[Middle] = true;
      s_helding_down[Middle] = false;
      break;
    }
    case WM_RBUTTONUP:
    {
      s_released[Right] = true;
      s_helding_down[Middle] = false;
      break;
    }
    case WM_MOUSEMOVE:
    {
      // TODO
      break;
    }
    case WM_MOUSEWHEEL:
    {
      s_scroll_delta += GET_WHEEL_DELTA_WPARAM(wparam);
      break;
    }
    default:
    {
      // Not a mouse message, so exit
      return;
    }
  }

  // All mouse messages provide a new pointer position
  s_position.x = static_cast<short>(LOWORD(lparam)); // GET_X_LPARAM(lParam);
  s_position.y = static_cast<short>(HIWORD(lparam)); // GET_Y_LPARAM(lParam);
}

void Mouse::Update() {
  // clear state from last frame.
  s_helding_down.clear();
  s_pressed.clear();
  s_released.clear();
}

Math::Vector2 Mouse::GetPosition() {
  return s_position;
}

int Mouse::GetScrollDelta() {
  return s_scroll_delta;
}

bool Mouse::IsHeldingDown(Button button) {
  return s_helding_down[button];
}

bool Mouse::IsPressed(Button button) {
  return s_pressed[button];
}

bool Mouse::IsReleased(Button button) {
  return s_released[button];
}

}  // namespace Input
}  // namespace LL3D