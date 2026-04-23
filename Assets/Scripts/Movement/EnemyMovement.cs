using UnityEngine;

public class EnemyMovement : MovementComponent
{
    private void Update()
    {
        SetMovementDirection();
    }

    public void MoveEnemy(Vector3 point)
    {
        MoveToPoint(point);
    }
}
