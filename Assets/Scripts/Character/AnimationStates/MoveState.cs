using UnityEngine;

public class MoveState : AnimationState
{
    public MoveState(AnimationStateMachine stateMachine, AnimationController controller, MovementComponent movementComponent, AnimationStateType type)
        : base(stateMachine, controller, movementComponent, type) { }

    public override void Enter(float transitionTime)
    {
        _controller.Play("Run");
    }

    public override void Update()
    {
        if(_characterMovement.MovementDirection.magnitude < 0.05f)
        {
            _animationStateMachine.SetState(AnimationStateType.Idle, 0.1f);
        }
    }
}
