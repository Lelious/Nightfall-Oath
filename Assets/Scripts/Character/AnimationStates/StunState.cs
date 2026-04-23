using UnityEngine;

public class StunState : AnimationState
{
    public StunState(AnimationStateMachine stateMachine, AnimationController controller, MovementComponent movementComponent, AnimationStateType type)
        : base(stateMachine, controller, movementComponent, type) { }
    public override void Enter(float transitionTime)
    {
        _controller.Play("Stun");
    }
}
