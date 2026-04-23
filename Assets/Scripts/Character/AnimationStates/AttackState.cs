using UnityEngine;

public class AttackState : AnimationState
{
    public AttackState(AnimationStateMachine stateMachine, AnimationController controller, MovementComponent movementComponent, AnimationStateType type)
        : base(stateMachine, controller, movementComponent, type) { }

    public override void Enter(float transitionTime)
    {
        var rnd = Random.Range(0, 2);
        _controller.Play(rnd == 0 ? "Attack1" : "Attack2");
    }
}
