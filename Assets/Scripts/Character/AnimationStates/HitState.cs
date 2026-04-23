using UnityEngine;

public class HitState : AnimationState
{
    public HitState(AnimationStateMachine stateMachine, AnimationController controller, MovementComponent movementComponent, AnimationStateType type)
        : base(stateMachine, controller, movementComponent, type) { }

    public override void Enter(float transitionTime)
    {
        _controller.Play("Hit");
    }
}
