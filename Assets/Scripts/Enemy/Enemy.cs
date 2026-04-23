using System;
using System.Collections;
using UnityEngine;
using UnityEngine.EventSystems;

public class Enemy : MonoBehaviour, IPointerClickHandler
{
    public static event Action OnEnemyDeath;

    [SerializeField] private float _health;
    [SerializeField] private AnimationController _animationController;
    [SerializeField] private EnemyMovement _movementComponent;
    [SerializeField] private Character _character;
    [SerializeField] private float _attackSpeed = 1f;
    [SerializeField] private float _speed;
    [SerializeField] private EquippedWeaponType _weaponType;
    [SerializeField] private EnemyData _enemyData;
    [SerializeField] private HealthComponent _healthComponent;
    [SerializeField] private EnemyAIBehaviour _aiBehaviour;
    [SerializeField] private float _attackDistance = 1.5f;
    [SerializeField] private DroppedItem _healthPot; //TEST

    private void Start()
    {
        InitializeEnemy();
        _animationController.SetAttackSpeed(_attackSpeed);
    }


    public void InitializeEnemy()
    {
        _aiBehaviour.SetInitialPosition(transform.position);
        _aiBehaviour.RunBehaviour();
        _healthComponent.InitializeHealth(_enemyData);
        _animationController.ApplyAnimationSet(_weaponType);
        _healthComponent.OnHealthChanged += CheckAliveCondition;
    }


    public EquippedWeaponType GetCurrentWeaponType() => _weaponType;
    public HealthComponent GetHealth() => _healthComponent;
    public float GetCreatureFrameScale() => _enemyData.FrameScale;
    public float GetAttackDistance() => _attackDistance;
    public EnemyData GetData() => _enemyData;

    public void CheckAliveCondition(float health)
    {
        if (health <= 0)
        {
            _aiBehaviour.StopBehaviour();
            OnEnemyDeath?.Invoke();
            //var pot = Instantiate(_healthPot, transform.position, Quaternion.Euler(60f, 0f, 0f));
            //pot.InitializeItem();
            Destroy(gameObject, 3f);
        }
    }

    public void OnPointerClick(PointerEventData eventData)
    {
        var finder = FindFirstObjectByType<TargetFinderComponent>();
        finder.SetTarget(this);
        finder.StopAutotarget();
    }
}
