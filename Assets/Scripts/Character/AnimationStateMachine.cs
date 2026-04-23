public class AnimationStateMachine
{
    public AnimationState CurrentState;

    private IdleState idle;
    private MoveState move;
    private AttackState attack;
    private HitState hit;
    private StunState stun;
    private DeathState death;
    private SpellCastState spellCast;
    private BuffState buffState;


    public AnimationStateMachine(AnimationController controller, MovementComponent movementComponent)
    {
        idle = new IdleState(this, controller, movementComponent, AnimationStateType.Idle);
        move = new MoveState(this, controller, movementComponent, AnimationStateType.Run);
        attack = new AttackState(this, controller, movementComponent, AnimationStateType.Attack);
        spellCast = new SpellCastState(this, controller, movementComponent, AnimationStateType.Cast);
        buffState = new BuffState(this, controller, movementComponent, AnimationStateType.Buff);
        hit = new HitState(this, controller, movementComponent, AnimationStateType.Hit);
        stun = new StunState(this, controller, movementComponent, AnimationStateType.Stun);
        death = new DeathState(this, controller, movementComponent, AnimationStateType.Death);
    }

    public void SetState(AnimationStateType newStateType, float transitionTime)
    {
        var newState = GetState(newStateType);

        if (CurrentState != null)
        {
            if (!CanTransition(CurrentState.AnimType, newState.AnimType))
                return;

            if (CurrentState == newState)
                return;

            CurrentState.Exit();
        }

        CurrentState = newState;
        CurrentState.Enter(transitionTime);
    }

    public void ReturnToIdle(float transitionTime)
    {
        if (CurrentState.AnimType == AnimationStateType.Death)
            return;

        CurrentState.Exit();

        CurrentState = GetState(AnimationStateType.Idle);
        CurrentState.Enter(transitionTime);
    }

    public void ForceSetState(AnimationStateType newStateType, float transitionTime)
    {
        var newState = GetState(newStateType);
        CurrentState?.Exit();
        CurrentState = newState;
        CurrentState.Enter(transitionTime);
    }

    public void Update()
    {
        CurrentState?.Update();
    }

    private bool CanTransition(AnimationStateType current, AnimationStateType next)
    {
        if (current == AnimationStateType.Death)
            return false;

        if (current == AnimationStateType.Stun)
            return next == AnimationStateType.Death;

        if (current == AnimationStateType.Hit)
            return next == AnimationStateType.Stun || next == AnimationStateType.Death;

        if (current == AnimationStateType.Attack)
            return next == AnimationStateType.Hit ||
                   next == AnimationStateType.Stun ||
                   next == AnimationStateType.Death;

        return true;
    }

    private AnimationState GetState(AnimationStateType type)
    {
        return type switch
        {
            AnimationStateType.Idle => idle,
            AnimationStateType.Run => move,
            AnimationStateType.Attack => attack,
            AnimationStateType.Hit => hit,
            AnimationStateType.Cast => spellCast,
            AnimationStateType.Death => death,
            AnimationStateType.Stun => stun,
            AnimationStateType.Buff => buffState,
            _ => idle
        };
    }
}
