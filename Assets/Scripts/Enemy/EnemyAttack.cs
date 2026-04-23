using System.Collections;
using UnityEngine;

public class EnemyAttack : AttackComponent
{
    [SerializeField] private MovementComponent _movementComponent;
    [SerializeField] private Enemy _enemy;
    [SerializeField] private float _minAttack = 5f;
    [SerializeField] private float _maxAttack = 15f;

    private Coroutine _chaseRoutine;
    private float _attackDistance;
    private Character _targetToChase;

    public void SetCharacter(Character character) => _targetToChase = character;

    public override void MakeAttack()
    {
        if (_enemy.GetCurrentWeaponType().Equals(EquippedWeaponType.Bow))
        {
            var arrow = Instantiate(_arrowPrefab, _arrowShootPoint.position, transform.rotation);
        }
        else
        {
            if (_targetToChase != null && _targetToChase.GetHealth().IsAlive())
            {
                _targetToChase.GetHealth().TakeDamage(Random.Range(_minAttack, _maxAttack));
            }
        }
    }

    public override void PerformAttack(Enemy enemy)
    {
        _attackDistance = _enemy.GetAttackDistance();     

        if (Vector3.Distance(transform.position, _targetToChase.transform.position) > _attackDistance)
        {
            _movementComponent.MoveToPoint(_targetToChase.transform.position);

            if (_chaseRoutine != null)
            {
                StopCoroutine(_chaseRoutine);
            }

            _chaseRoutine = StartCoroutine(ChaseRoutine());
            return;
        }
        
        _animationController.MakeCharacterAttack(_targetToChase.transform.position);
    }

    public void StopAttack()
    {
        _targetToChase = null;
        if (_chaseRoutine != null)
            StopCoroutine(_chaseRoutine);
    }

    private IEnumerator ChaseRoutine()
    {
        while (Vector3.Distance(transform.position, _targetToChase.transform.position) > _attackDistance)
        {
            yield return new WaitForSeconds(0.1f);
        }

        if (_targetToChase.GetHealth().IsAlive())
        {
            PerformAttack(_enemy);
        }

        _chaseRoutine = null;
    }

    public override void CancelChase()
    {
        if (_chaseRoutine != null)
        {
            StopCoroutine(_chaseRoutine);
            _chaseRoutine = null;
        }
    }
}
