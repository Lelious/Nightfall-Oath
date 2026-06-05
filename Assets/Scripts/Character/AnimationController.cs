using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class AnimationController : MonoBehaviour
{
    [SerializeField] private MovementComponent _movementComponent;
    [SerializeField] private AttackComponent _attackComponent;
    [SerializeField] private Animator _animator;
    [SerializeField] private float _attackSpeed = 1f;
    [SerializeField] private float _castSpeed = 1f;
    [SerializeField] private List<WeaponAnimationPreset> _animationPresets = new();

    private AnimatorOverrideController _overrideController;
    private AnimationStateMachine _stateMachine;
    private WeaponAnimationPreset _currentSet;
    private Coroutine _hitRoutine;

    private bool _isAttacking;
    private bool _isFreeze;

    private void Awake()
    {
        InitializeService();
    }

    public void InitializeService()
    {
        _stateMachine = new AnimationStateMachine(this, _movementComponent);
        _overrideController = new AnimatorOverrideController(_animator.runtimeAnimatorController);
        _animator.runtimeAnimatorController = _overrideController;
        _stateMachine.SetState(AnimationStateType.Idle, 0f);
        ApplyAnimationSet(EquippedWeaponType.Unarmed);
    }

    private void Update()
    {
        _stateMachine.Update();

        if (_isAttacking)
        {
            if (_stateMachine.CurrentState.AnimType != AnimationStateType.Attack)
            {
                _isAttacking = false;
                _movementComponent.IsLockedMovement = false;
            }
        }
    }

    public void ApplyAnimationSet(EquippedWeaponType weaponType)
    {
        _currentSet = _animationPresets.Find(x => x.WeaponType.Equals(weaponType));

        _overrideController["Idle"] = _currentSet.AnimationSet.Idle;
        _overrideController["Run"] = _currentSet.AnimationSet.Run;
        _overrideController["GetHit"] = _currentSet.AnimationSet.Hit;
        _overrideController["Attack1"] = _currentSet.AnimationSet.Attack1;
        _overrideController["Attack2"] = _currentSet.AnimationSet.Attack2;
        _overrideController["Death"] = _currentSet.AnimationSet.Death;
    }

    [ContextMenu("StunEnter")]
    public void StunEnter()
    {
        _movementComponent.StopMovement();
        _stateMachine.SetState(AnimationStateType.Stun, 0.1f);
    }

    [ContextMenu("StunExit")]
    public void StunExit()
    {
        _isFreeze = false;
        _movementComponent.IsLockedMovement = false;
        _stateMachine.ReturnToIdle(0.1f);
    }

    [ContextMenu("Hit")]
    public void Hit()
    {
        _movementComponent.StopMovement();
        _movementComponent.IsLockedMovement = true;
        _isAttacking = false;
        _stateMachine.SetState(AnimationStateType.Hit, 0.2f);
        if (_hitRoutine != null)
            StopCoroutine(_hitRoutine);

        _hitRoutine = StartCoroutine(HitCoroutine());
    }

    public void HitVisual()
    {
        _animator.Play("HitVisual");
    }

    private IEnumerator HitCoroutine()
    {
        yield return new WaitForSeconds(0.2f);

        if (_stateMachine.CurrentState.AnimType == AnimationStateType.Hit)
        {
            _stateMachine.ReturnToIdle(0.2f);
        }

        yield return new WaitForSeconds(0.1f);
        _isFreeze = false;
        _isAttacking = false;
        _movementComponent.IsLockedMovement = false;
    }

    public bool MakeAttack(Vector3 position)
    {
        if (_isFreeze) return false;
        if (_isAttacking) return false;
        _isAttacking = true;
        _movementComponent.IsLockedMovement = true;
        _movementComponent.StopMovement();
        var dir = new Vector3(position.x, transform.position.y, position.z) - transform.position;
        transform.rotation = Quaternion.LookRotation(dir);
        _stateMachine.SetState(AnimationStateType.Attack, 0.15f);
        return true;
    }

    public void SuccessAttack()
    {
        _attackComponent.MakeAttack();
        _animator.speed = 1f;
    }

    public void Death()
    {
        if (_hitRoutine != null)
            StopCoroutine(_hitRoutine);

        _isFreeze = true;
        _movementComponent.IsLockedMovement = true;
        _stateMachine.ForceSetState(AnimationStateType.Death, 0.1f);
    }

    [ContextMenu("SpellRelease")]
    public void SpellRelease()
    {
        _movementComponent.IsLockedMovement = false;
        _stateMachine.ReturnToIdle(0.1f);
    }

    [ContextMenu("SpellCast")]
    public void SpellCast()
    {
        _movementComponent.StopMovement();
        _stateMachine.SetState(AnimationStateType.Cast, 0.1f);
    }

    public void AttackExit()
    {
        _isAttacking = false;
        _movementComponent.IsLockedMovement = false;
        _stateMachine.ReturnToIdle(0.25f);
    }

    public void PlayCrossFade(string stateName, float transitionTime)
    {
        _animator.CrossFade(stateName, transitionTime, 0, 0f);
    }
    public void Play(string stateName)
    {
        _animator.Play(stateName, 0, 0f);
    }

    public void SetAttackSpeed(float speedModifier)
    {
        _animator.SetFloat("AttackSpeed", speedModifier);
    }   

    public void SetCastSpeed(float castModifier)
    {
        _animator.SetFloat("CastSpeed", castModifier);
    }

    public Animator GetAnimator() => _animator;
}

[Serializable]
public class WeaponAnimationPreset
{
    public EquippedWeaponType WeaponType;
    public AnimationSet AnimationSet;
}

public enum AnimationStateType
{
    Idle,
    Run,
    Attack,
    Hit,
    Death,
    Stun,
    Cast,
    Buff
}
