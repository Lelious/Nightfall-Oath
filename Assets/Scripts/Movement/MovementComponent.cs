using UnityEngine;
using UnityEngine.AI;

public abstract class MovementComponent : MonoBehaviour
{
    [SerializeField] private NavMeshAgent _agent;

    public Vector3 MovementDirection;
    public bool IsLockedMovement;

    private void Awake()
    {
        _agent.obstacleAvoidanceType = ObstacleAvoidanceType.NoObstacleAvoidance;
        _agent.avoidancePriority = 50;
    }

    private void LateUpdate()
    {
        SetMovementDirection();
    }

    public virtual void SetStopDistance(float stopDistance)
    {
        _agent.stoppingDistance = stopDistance;
    }

    public virtual void Move(Vector3 point, float speed)
    {
        if (IsLockedMovement) return;

        if (point.magnitude > 0.1f && _agent.isActiveAndEnabled)
        {
            _agent.isStopped = true;
            _agent.Move(_agent.speed * speed * Time.deltaTime * point);
            transform.rotation = Quaternion.LookRotation(point);
            MovementDirection = point;
        }
    }

    public virtual void MoveToPoint(Vector3 point)
    {
        if (!_agent.isActiveAndEnabled || IsLockedMovement || !_agent.isOnNavMesh) return;
        _agent.isStopped = false;
        _agent.SetDestination(point);
    }

    public virtual void StopMovement()
    {
        _agent.isStopped = true;     
    }

    public virtual void SetMovementDirection()
    {
        MovementDirection = _agent.velocity.normalized;
    }

    public virtual void SetSpeed(float speed)
    {
        _agent.speed = speed;
    }
}
