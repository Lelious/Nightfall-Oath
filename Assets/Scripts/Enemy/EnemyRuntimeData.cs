using UnityEngine;

public class EnemyRuntimeData
{
    public string Name { get; private set; }
    public Avatar Avatar { get; private set; }
    public int Level { get; private set; }
    public int MaxHealth { get; private set; }
    public int Damage { get; private set; }
    public bool Elite { get; private set; }
    public float FrameScale { get; private set; }
    public float AttackSpeed { get; private set; }
    public float Speed { get; private set; }

    public EnemyRuntimeData(EnemyData data, int level, bool elite)
    {
        Name = data.Name;
        Avatar = data.Avatar;
        Level = level;
        Elite = elite;
        AttackSpeed = data.AttackSpeed;
        Speed = data.Speed;
        MaxHealth = CalculateHealth(data, level);
        Damage = CalculateDamage(data, level);

        FrameScale = Elite
            ? data.FrameScale * data.EliteFrameScaleMultiplier
            : data.FrameScale;
    }

    private int CalculateHealth(EnemyData data, int level)
    {
        float scaledHealth = data.BaseHealth * (1f + (data.HealthScalePerLevel * (level - 1)));

        if (data.Elite)
        {
            scaledHealth *= data.EliteHealthMultiplier;
        }

        return Mathf.RoundToInt(scaledHealth);
    }

    private int CalculateDamage(EnemyData data, int level)
    {
        float scaledDamage = data.BaseDamage * (1f + (data.DamageScalePerLevel * (level - 1)));

        if (data.Elite)
        {
            scaledDamage *= data.EliteDamageMultiplier;
        }

        return Mathf.RoundToInt(scaledDamage);
    }
}
