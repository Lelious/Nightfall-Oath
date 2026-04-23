using UnityEngine;

public class BuffState : AnimationState
{
    public BuffState(AnimationStateMachine stateMachine, AnimationController controller, MovementComponent movementComponent, AnimationStateType type)
        : base(stateMachine, controller, movementComponent, type) { }
    public override void Enter(float transitionTime)
    {
        _controller.PlayCrossFade("Buff", transitionTime);
    }
}
