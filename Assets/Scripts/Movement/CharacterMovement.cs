using UnityEngine;

public class CharacterMovement : MovementComponent
{
    [SerializeField] private AttackComponent _attackComponent;
    [SerializeField] private Joystick _joystick;
    [SerializeField] private float _speed;

    private void Update()
    {
        Vector2 input = _joystick.Direction;
        Vector3 dir = new Vector3(input.x, 0f, input.y);

        if (dir.magnitude < 0.1f)
        {           
            return;
        }

        Move(dir.normalized, _speed);
        _attackComponent.CancelChase();
    }
}
