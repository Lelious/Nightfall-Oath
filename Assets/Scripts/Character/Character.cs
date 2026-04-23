using UnityEngine;

public class Character : MonoBehaviour
{
    [SerializeField] private CharacterMovement _characterMovement;
    [SerializeField] private FixedJoystick _joystick;
    [SerializeField] private AnimationController _animationController;
    [SerializeField] private MovementComponent _movementComponent;
    [SerializeField] private float _attackSpeed = 1f;
    [SerializeField] private float _castSpeed = 1f;
    [SerializeField] private EquippedWeaponType _weaponType;
    [SerializeField] private Transform _leftHand, _rightHand;
    [SerializeField] private HealthComponent _healthComponent;
    [SerializeField] private EnemyData _data;  //TEST DEBUG

    private float _attackDistance = 1.5f;
    private GameObject _handWeapon;

    private void Awake()
    {
        _healthComponent.InitializeHealth(_data);
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

        _handWeapon = Instantiate(item.Prefab, item.WeaponType.Equals(EquippedWeaponType.Bow) ? _leftHand : _rightHand);
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
}

public enum EquippedWeaponType
{
    Unarmed,
    Bow,
    Sword,
    Sword2H,
    Throw
}
