using UnityEngine;

public class SpellCastState : AnimationState
{
    public SpellCastState(AnimationStateMachine stateMachine, AnimationController controller, MovementComponent movementComponent, AnimationStateType type)
        : base(stateMachine, controller, movementComponent, type) { }

    public override void Enter(float transitionTime)
    {
        _controller.PlayCrossFade("SpellCast", transitionTime);
    }
}
