using System.Collections;
using UnityEngine;
using UnityEngine.UI;

public class CharacterAttack : AttackComponent
{
    [SerializeField] private Character _character;
    [SerializeField] private Button _attackButton;
    [SerializeField] private TargetFinderComponent _targetFinder;
    [SerializeField] private MovementComponent _movementComponent;

    private Enemy _targetToChase;
    private Enemy _targetToAttack;
    private Coroutine _chaseRoutine;
    private float _attackDistance;

    private void Awake()
    {
        _attackButton.onClick.AddListener(delegate { PerformAttack(null); });
    }

    public override void MakeAttack()
    {
        if (_character.GetCurrentWeaponType().Equals(EquippedWeaponType.Bow))
        {
            var arrow = Instantiate(_arrowPrefab, _arrowShootPoint.position, transform.rotation);
        }
        else
        {
            if(_targetToAttack != null && _targetToAttack.GetHealth().IsAlive())
            {
                _targetToAttack.GetHealth().TakeDamage(20f);
            }
        }
    }

    public override void PerformAttack(Enemy enemy)
    {
        if (!_character.GetHealth().IsAlive()) return;

        _attackDistance = _character.GetAttackDistance();
        var target = enemy == null ? _targetFinder.GetPossibleTarget(transform.position, _attackDistance) : enemy;

        if (target == null) return;        

        if(Vector3.Distance(transform.position, target.transform.position) > _attackDistance)
        {
            _movementComponent.MoveToPoint(target.transform.position);
            _targetToChase = target;

            if(_chaseRoutine != null)
            {
                StopCoroutine(_chaseRoutine);
            }

            _chaseRoutine = StartCoroutine(ChaseRoutine());
            return;
        }
      
        _animationController.MakeCharacterAttack(target.transform.position);
        _targetToAttack = target;
    }

    private IEnumerator ChaseRoutine()
    {
        while (Vector3.Distance(transform.position, _targetToChase.transform.position) > _attackDistance)
        {
            yield return new WaitForSeconds(0.1f);
        }

        if(_targetToChase.GetHealth().IsAlive())
        {
            PerformAttack(_targetToChase);
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
}
