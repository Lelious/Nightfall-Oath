using UnityEngine;
using UnityEngine.AI;

public class MovementComponent : MonoBehaviour
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

    public void SetStopDistance(float stopDistance)
    {
        _agent.stoppingDistance = stopDistance;
    }

    public void Move(Vector3 point, float speed)
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

    public void MoveToPoint(Vector3 point)
    {
        if (!_agent.isActiveAndEnabled || IsLockedMovement || !_agent.isOnNavMesh) return;
        _agent.isStopped = false;
        _agent.SetDestination(point);
    }

    public void StopMovement()
    {
        _agent.isStopped = true;     
    }

    public void SetMovementDirection()
    {
        MovementDirection = _agent.velocity.normalized;
    }
}
