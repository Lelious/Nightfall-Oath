using UnityEngine;

public class DeathState : AnimationState
{
    public DeathState(AnimationStateMachine stateMachine, AnimationController controller, MovementComponent movementComponent, AnimationStateType type)
        : base(stateMachine, controller, movementComponent, type) { }

    public override void Enter(float transitionTime)
    {
        _controller.Play("Death");
    }
}
