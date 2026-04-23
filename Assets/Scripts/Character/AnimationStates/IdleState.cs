public class IdleState : AnimationState
{
    public IdleState(AnimationStateMachine stateMachine, AnimationController controller, MovementComponent movementComponent, AnimationStateType type)
        : base(stateMachine, controller, movementComponent, type) { }

    public override void Enter(float transitionTime)
    {
        _controller.PlayCrossFade("Idle", transitionTime);
    }

    public override void Update()
    {
        if (_characterMovement.MovementDirection.magnitude > 0.05f)
        {
            _animationStateMachine.SetState(AnimationStateType.Run, 0f);
        }
    }
}
