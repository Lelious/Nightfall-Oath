using UnityEngine;
using UnityEngine.AI;

public class PlayerController : MonoBehaviour
{
    [SerializeField] private NavMeshAgent _agent;
    [SerializeField] private Animator _animator;
    [SerializeField] private Joystick _joystick;

    void Update()
    {
        Vector2 input = _joystick.Direction;
        Vector3 dir = new Vector3(input.x, 0, input.y);

        if (dir.magnitude > 0.1f)
        {
            _agent.Move(dir * _agent.speed * Time.deltaTime);
            transform.rotation = Quaternion.LookRotation(dir);
        }

        _animator.SetBool("Run", dir.magnitude > 0.1f);
    }
}
