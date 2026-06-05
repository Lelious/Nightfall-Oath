using UnityEngine;
using UniRx;

public class InputService
{
    public IReadOnlyReactiveProperty<Vector2> MovementInput => _movementInput;    
    private readonly ReactiveProperty<Vector2> _movementInput = new(Vector2.zero);

    public IReadOnlyReactiveProperty<ushort> ActionSpellId => _actionSpellId;
    private readonly ReactiveProperty<ushort> _actionSpellId = new(0);

    public IReadOnlyReactiveProperty<Enemy> CurrentTarget => _currentTarget;
    public IReadOnlyReactiveProperty<bool> IsAutotarget => _isAutotarget;
    private readonly ReactiveProperty<Enemy> _currentTarget = new(null);
    private readonly ReactiveProperty<bool> _isAutotarget = new(false);

    public void SetMovementInput(Vector2 input) => _movementInput.Value = input;
    public void SetActiveSpell(ushort actionId) => _actionSpellId.Value = actionId;

    public void SetTarget(Enemy target, bool isAutotarget)
    {
        _currentTarget.Value = target;
        _isAutotarget.Value = isAutotarget;
    }

    public void CancelTarget()
    {
        _currentTarget.Value = null;
        _isAutotarget.Value = true;
    }
}
