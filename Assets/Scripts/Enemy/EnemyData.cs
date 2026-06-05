using UnityEngine;

[CreateAssetMenu(fileName = "EnemyData", menuName = "ScriptableObjects/EnemyData", order = 1)]
public class EnemyData : ScriptableObject
{
    public string AssetAddress;
    public string Name;
    public Avatar Avatar;
    public float FrameScale;

    public int BaseHealth;
    public int BaseDamage;
    public float AttackSpeed;
    public float Speed;

    public float HealthScalePerLevel;
    public float DamageScalePerLevel;

    public bool Elite;

    public float EliteHealthMultiplier;
    public float EliteDamageMultiplier;
    public float EliteFrameScaleMultiplier;
}
