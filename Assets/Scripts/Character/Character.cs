using UniRx;
using UnityEngine;
using Zenject;

public class Character : MonoBehaviour
{
    [SerializeField] private AnimationController _animationController;
    [SerializeField] private CharacterMovement _movementComponent;
    [SerializeField] private CharacterAttack _attackComponent;
    [SerializeField] private HealthComponent _healthComponent;
    [SerializeField] private Transform _leftHand, _rightHand;
    [SerializeField] private Collider _hitCollider;

    [SerializeField] private float _attackSpeed = 1f;
    [SerializeField] private float _castSpeed = 1f;

    [SerializeField] private EquippedWeaponType _weaponType;

    private TargetingService _targetingService;
    private IInstantiator _instantiator;
    private CompositeDisposable _disposables = new();
    private GameObject _handWeapon;

    private float _attackDistance = 1.5f;

    [Inject]
    public void Construct(IInstantiator instantiator, TargetingService targetingService)
    {
        _instantiator = instantiator;
        _healthComponent.InitializeHealth(new HealthData(100, 100)); // Fill with normal data later
        _targetingService = targetingService;
        _targetingService.SetCharacter(this);

        _healthComponent.CurrentHp.
            Subscribe(value => OnHit(value))
            .AddTo(_disposables);
    }

    void Update()
    {
        _animationController.SetAttackSpeed(_attackSpeed);
        _animationController.SetCastSpeed(_castSpeed);
    }

    public HealthComponent GetHealth() => _healthComponent;

    public void WeaponEquipped(Item item)
    {
        if (_handWeapon != null)
        {
            Destroy(_handWeapon);
        }

        if (item == null)
        {
            _weaponType = EquippedWeaponType.Unarmed;
            _animationController.ApplyAnimationSet(_weaponType);
            _attackDistance = 1.5f;
            _movementComponent.SetStopDistance(_attackDistance);

            return;
        }

        _handWeapon = _instantiator.InstantiatePrefab(item.Prefab, item.WeaponType.Equals(EquippedWeaponType.Bow) ? _leftHand : _rightHand);
        _weaponType = item.WeaponType;
        _animationController.ApplyAnimationSet(_weaponType);
        _attackDistance = item.AttackDistance;
        _movementComponent.SetStopDistance(_attackDistance);
    }

    public EquippedWeaponType GetCurrentWeaponType()
    {
        return _weaponType;      
    }

    public float GetAttackDistance() => _attackDistance;

    private void OnHit(float health)
    {
        if (health <= 0)
        {
            _animationController.Death();
            _hitCollider.enabled = false;
        }
        else
        {
            _animationController.HitVisual();
        }
    }
}

public enum EquippedWeaponType
{
    Unarmed,
    Bow,
    Sword,
    Sword2H,
    Throw
}
