using UnityEngine;

[CreateAssetMenu(menuName = "Animations/Override Set")]
public class AnimationSet : ScriptableObject
{
    public AnimationClip Idle;
    public AnimationClip Run;
    public AnimationClip Hit;
    public AnimationClip Attack1;
    public AnimationClip Attack2;
    public AnimationClip Death;
}
