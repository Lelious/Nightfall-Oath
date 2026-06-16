using Cysharp.Threading.Tasks;
using UniRx;
using UnityEngine;
using Zenject;

public class Enemy : MonoBehaviour, IMapCreature
{
    [SerializeField] private ushort _id;
    [SerializeField] private AnimationController _animationController;
    [SerializeField] private EnemyMovement _movementComponent;
    [SerializeField] private HealthComponent _healthComponent;
    [SerializeField] private EnemyAIBehaviour _aiBehaviour;
    [SerializeField] private Collider _hitCollider;

    [SerializeField] private float _attackDistance = 1.5f;
    [SerializeField] private float _attackSpeed = 1f;
    [SerializeField] private float _speed;

    [SerializeField] private EquippedWeaponType _weaponType;

    private readonly CompositeDisposable _disposables = new();
    private DamageProcessService _damageService;
    private TargetingService _targetingService;    
    private EnemyRuntimeData _runtimeData;
    private EnemyFactory _enemyFactory;
    private GameObject _view;

    private byte _creatureType;
    private ushort _level;
    private bool _elite;

    public void SetRotation(Quaternion rotation) => transform.rotation = rotation;
    public void SetPosition(Vector3 position) => transform.position = position;
    public void SetScale(Vector3 scale) => transform.localScale = scale;
    public void SetActive(bool active) => gameObject.SetActive(active);
    public EquippedWeaponType GetCurrentWeaponType() => _weaponType;
    public HealthComponent GetHealth() => _healthComponent;
    public bool Active() => gameObject.activeInHierarchy;
    public float GetAttackDistance() => _attackDistance;
    public Quaternion Rotation() => transform.rotation;
    public EnemyRuntimeData GetData() => _runtimeData;
    public Vector3 Position() => transform.position;
    public Vector3 Scale() => transform.localScale;
    public GameObject GetCreatureView() => _view;
    public Transform Transform() => transform;
    public ushort Id() => _id;

    [Inject]
    public void Construct(TargetingService targetingService, EnemyFactory factory, DamageProcessService damageService)
    {
        _targetingService = targetingService;
        _enemyFactory = factory;
        _damageService = damageService;
    }

    public void SetupCreatureMapInfo(byte creatureType, ushort level)
    {
        _creatureType = creatureType;
        _level = level;
    }

    public (byte, ushort, bool) GetCreatureTypeAndLvl()
    {
        return (_creatureType, _level, _elite);
    }

    public void InitializeCreature(EnemyRuntimeData data, GameObject view)
    {
        _runtimeData = data;
        _hitCollider.enabled = true;
        _view = view;

        RebindDependencies();
    }

    private void RebindDependencies()
    {
        _animationController.SetAttackSpeed(_runtimeData.AttackSpeed);
        _movementComponent.SetSpeed(_runtimeData.Speed);

        var animator = _animationController.GetAnimator();
        animator.avatar = _runtimeData.Avatar;
        animator.Rebind();
        animator.Update(0f);

        _aiBehaviour.SetInitialPosition(transform.position);
        _aiBehaviour.RunBehaviour(_targetingService, _damageService);
        _healthComponent.InitializeHealth(new HealthData(_runtimeData.MaxHealth, 0)); 
        _animationController.ApplyAnimationSet(_weaponType);
        _targetingService.AddEnemyToTargeting(this);

        _healthComponent.CurrentHp.
            Subscribe(value => OnHit(value))
            .AddTo(_disposables);
    }

    private void OnHit(float health)
    {
        if (health <= 0)
        {
            _aiBehaviour.StopBehaviour();
            _animationController.Death();
            _hitCollider.enabled = false;
            _targetingService.RemoveEnemyFromTargeting(this);
            ReturnToPool().Forget();
        }
        else
        {
            _animationController.HitVisual();
        }
    }

    private async UniTask ReturnToPool()
    {
        await UniTask.WaitForSeconds(3f);
        _enemyFactory.DestroyEnemy(this);
    }

    public MapObjectType ObjType() => MapObjectType.Creature;
}
