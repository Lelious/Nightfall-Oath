using UnityEngine;

public abstract class AnimationState
{
    public AnimationStateType AnimType;
    protected AnimationStateMachine _animationStateMachine;
    protected MovementComponent _characterMovement;
    protected AnimationController _controller;

    public AnimationState(AnimationStateMachine stateMachine, AnimationController controller, MovementComponent movementComponent, AnimationStateType type)
    {
        _animationStateMachine = stateMachine;
        _characterMovement = movementComponent;
        _controller = controller;
        AnimType = type;
    }
    public void ForceInterruptAnimationState(float transitionTime)
    {
        _animationStateMachine.ForceSetState(AnimationStateType.Idle, transitionTime);
    }

    public virtual void Enter(float transitionTime) { }
    public virtual void Exit() { }
    public virtual void Update() { }
}
