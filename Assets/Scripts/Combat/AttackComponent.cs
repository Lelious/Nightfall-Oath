using UnityEngine;

public abstract class AttackComponent : MonoBehaviour
{
    [SerializeField] protected AnimationController _animationController;
    [SerializeField] protected GameObject _arrowPrefab;
    [SerializeField] protected Transform _arrowShootPoint;

    public abstract void MakeAttack();
    public abstract void CancelChase();
    public abstract void PerformAttack(ushort spellId);
}
