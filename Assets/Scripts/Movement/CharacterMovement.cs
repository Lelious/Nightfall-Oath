using UnityEngine;
using Zenject;

public class CharacterMovement : MovementComponent
{
    [SerializeField] private AttackComponent _attackComponent;
    [SerializeField] private float _speed;

    private InputService _inputService;

    [Inject]
    public void Construct(InputService inputService)
    {
        _inputService = inputService;
    }

    private void Update()
    {
        if (_inputService == null) return;

        Vector2 input = _inputService.MovementInput.Value;
        Vector3 dir = new Vector3(input.x, 0f, input.y);

        if (dir.magnitude < 0.1f)
        {           
            return;
        }

        Move(dir.normalized, _speed);
        _attackComponent.CancelChase();
    }
}
