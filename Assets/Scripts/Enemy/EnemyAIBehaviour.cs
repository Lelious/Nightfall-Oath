using System.Collections;
using UnityEngine;

public class EnemyAIBehaviour : MonoBehaviour
{
    [SerializeField] private EnemyAttack _attackComponent;
    [SerializeField] private MovementComponent _movementComponent;
    [SerializeField] private Character _character;
    [SerializeField] private Enemy _enemy;

    private Coroutine _aiRoutine;
    private float _actionTime;
    private AIBehaviourState _currentState;
    private Vector3 _initialPosition;

    public void SetInitialPosition(Vector3 position) => _initialPosition = position;

    public void RunBehaviour()
    {
        _attackComponent.SetCharacter(_character);
        _currentState = AIBehaviourState.Idle;

        _aiRoutine = StartCoroutine(AIBehaviourRoutine());
    }

    public void StopBehaviour()
    {
        _movementComponent.StopMovement();
        _attackComponent.StopAttack();
        StopCoroutine(_aiRoutine);
    }

    private IEnumerator AIBehaviourRoutine()
    {
        while(true)
        {            
            if(_currentState.Equals(AIBehaviourState.Idle))
            {
                if(TryFindTarget())
                {
                    _currentState = AIBehaviourState.Chase;
                    _attackComponent.PerformAttack(_enemy);
                }
                else
                {
                    if(_actionTime <= 0f)
                    {
                        _actionTime = Random.Range(3f, 7f);
                        var rnd = Random.Range(0, 2);

                        if(rnd == 1)
                        {
                            _movementComponent.MoveToPoint(_initialPosition + new Vector3(Random.Range(-5f, 5f), 0f, Random.Range(-5f, 5f)));
                            _currentState = AIBehaviourState.Idle;
                        }
                    }
                    else
                    {
                        _actionTime -= 0.3f;
                    }
                }
            }
            else if(_currentState.Equals(AIBehaviourState.Chase))
            {
                if(TryFindTarget())
                {
                    _attackComponent.PerformAttack(_enemy);
                }
                else
                {
                    _currentState = AIBehaviourState.Idle;
                }
            }

            yield return new WaitForSeconds(0.3f);
        }
    }

    private bool TryFindTarget()
    {
        if (Vector3.Distance(transform.position, _character.transform.position) <= 8f && _character.GetHealth().IsAlive()) 
            return true;

        return false;
    }
}

public enum AIBehaviourState
{
    Idle,
    Chase,
    Patroll
}
