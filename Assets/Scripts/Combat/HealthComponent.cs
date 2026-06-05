using UniRx;
using UnityEngine;

public class HealthComponent : MonoBehaviour
{
    public IReadOnlyReactiveProperty<float> CurrentHp => _currentHp;
    public IReadOnlyReactiveProperty<float> CurrentMp => _currentMp;
    public IReadOnlyReactiveProperty<float> MaxHp => _maxHp;
    public IReadOnlyReactiveProperty<float> MaxMp => _maxMp;

    private readonly FloatReactiveProperty _currentHp = new(100);
    private readonly FloatReactiveProperty _maxHp = new(100);
    private readonly FloatReactiveProperty _currentMp = new(100);
    private readonly FloatReactiveProperty _maxMp = new(100);

    public bool IsAlive() => _currentHp.Value > 0;

    public void InitializeHealth(HealthData data)
    {
        _maxHp.Value = data.Health;
        _currentHp.Value = data.Health;

        _maxMp.Value = data.Mana;
        _currentMp.Value = data.Mana;
    }

    public void TakeDamage(float damage)
    {
        _currentHp.Value = Mathf.Clamp(_currentHp.Value - damage, 0, _maxHp.Value);
    }

    public void DecreaceMana(int value)
    {
        _currentMp.Value = Mathf.Clamp(_currentMp.Value - value, 0, _maxMp.Value);
    }
}

public struct HealthData
{
    public int Health;
    public int Mana;

    public HealthData(int health, int mana)
    {
        Health = health;
        Mana = mana;
    }
}
