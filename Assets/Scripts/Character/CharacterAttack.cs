using LeliousExtentions;
using System.Collections;
using UniRx;
using Unity.Mathematics;
using UnityEngine;
using Zenject;

public class CharacterAttack : AttackComponent
{
    [SerializeField] private MovementComponent _movementComponent;
    [SerializeField] private Character _character;  

    private readonly CompositeDisposable _disposables = new();
    private DamageProcessService _damageService;
    private TargetingService _targetingService;    
    private InputService _inputService;
    private Enemy _targetToChase;
    private Enemy _targetToAttack;
    private Coroutine _chaseRoutine;
    private float _attackDistance;

    private void Awake()
    {
        StartCoroutine(SetTargetFrame());
    }

    [Inject]
    public void Construct(TargetingService targetingService, InputService inputService, DamageProcessService damageService)
    {
        _targetingService = targetingService;
        _inputService = inputService;
        _damageService = damageService;

        Observable.EveryUpdate()
            .Where(_ => _inputService.ActionSpellId.Value > 0)
            .Subscribe(_ =>
            {
                PerformAttack(_inputService.ActionSpellId.Value);
            })
            .AddTo(_disposables);
    }

    public override void MakeAttack()
    {
        if (_character.GetCurrentWeaponType().Equals(EquippedWeaponType.Bow))
        {
            var arrow = Instantiate(_arrowPrefab, _arrowShootPoint.position, transform.rotation).GetComponent<Arrow>();
            arrow.InitializeArrow(_damageService);
        }
        else
        {
            if (_targetToAttack != null)
            {
                var crit = UnityEngine.Random.Range(0, 2);
                var damage = crit > 0 ? 40f : 20f;
                _damageService.ProcessDamage(_targetToAttack.GetHealth(), damage, crit > 0 ? DamageSource.Critical : DamageSource.Creature);
            }
        }
    }

    public override void PerformAttack(ushort spellId)
    {
        if (!_character.GetHealth().IsAlive()) return;

        if(spellId == 1)
        {
            _attackDistance = _character.GetAttackDistance();
            _targetToAttack = _targetToAttack == null ||
                                _targetToAttack.GetHealth().CurrentHp.Value <= 0 ||
                                LeliousMathematic.FlatDistanceGreaterThan(new float2(transform.position.x, transform.position.z), new float2(_targetToAttack.transform.position.x, _targetToAttack.transform.position.z), 1.5f) ?
                                _targetingService.FindTarget(transform.position) : _targetToAttack;

            if (_targetToAttack == null)
            {
                _inputService.SetTarget(null, true);
                return;
            }

            if (LeliousMathematic.FlatDistanceGreaterThan(new float2(transform.position.x, transform.position.z), new float2(_targetToAttack.transform.position.x, _targetToAttack.transform.position.z), _attackDistance))
            {               
                _targetToChase = _targetToAttack;

                if (_chaseRoutine != null)
                {
                    StopCoroutine(_chaseRoutine);
                }

                _chaseRoutine = StartCoroutine(ChaseRoutine());
                return;
            }
           
            var sucessAttack = _animationController.MakeAttack(_targetToAttack.transform.position);

            if(sucessAttack)
            {
                _character.GetHealth().DecreaceMana(5);
            }
        }
    }

    private void FindTarget()
    {
        _targetToAttack = _targetingService.FindTarget(transform.position);
        if(_targetToAttack != null)
        {
            _inputService.SetTarget(_targetToAttack, true);      
        }
    }

    private IEnumerator SetTargetFrame()
    {
        while (true)
        {
            if (_inputService.IsAutotarget.Value)
            {
                FindTarget();
                _inputService.SetTarget(_targetToAttack, true);
            }
            else
            {
                if (_targetToAttack == null)
                {
                    _inputService.CancelTarget();
                }
                else
                {
                    var cancelDistance = _inputService.IsAutotarget.Value == true ? 20f : 25f;

                    if (Vector3.Distance(transform.position, _targetToAttack.transform.position) > cancelDistance)
                    {
                        _inputService.CancelTarget();
                    }
                }
            }
            yield return new WaitForSeconds(0.3f);
        }
    }

    private IEnumerator ChaseRoutine()
    {
        while (LeliousMathematic.FlatDistanceGreaterThan(new float2(transform.position.x, transform.position.z), new float2(_targetToChase.transform.position.x, _targetToChase.transform.position.z), _attackDistance))
        {
            _movementComponent.MoveToPoint(_targetToAttack.transform.position);
            yield return new WaitForSeconds(0.1f);
        }

        if(_targetToChase.GetHealth().IsAlive())
        {
            PerformAttack(1);
        }

        _chaseRoutine = null;
    }

    public override void CancelChase()
    {
        if(_chaseRoutine != null)
        {
            StopCoroutine(_chaseRoutine);
            _chaseRoutine = null;
        }
    }

    private void OnDestroy()
    {
        _disposables.Dispose();
    }
}
