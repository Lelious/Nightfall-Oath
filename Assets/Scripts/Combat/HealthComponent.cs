using System;
using UnityEngine;

public class HealthComponent : MonoBehaviour
{
    public event Action<float> OnHealthChanged;

    [SerializeField] private float _health;
    [SerializeField] private AnimationController _animationController;
    [SerializeField] private Collider _hitCollider;
    [SerializeField] private float _currentHealth = 1;
    [SerializeField] private UIHealthAndManaService _healthManaService;

    public bool IsAlive() => _currentHealth > 0;

    public void InitializeHealth(EnemyData data)
    {
        _health = data.Health;
        _currentHealth = data.Health;
        _healthManaService?.UpdateHealth(_currentHealth, _health);
    }

    public void TakeDamage(float damage)
    {
        _currentHealth -= damage;

        if (_currentHealth <= 0)
        {
            _animationController.Death();
            _hitCollider.enabled = false;
            //Destroy(gameObject, 2f);
        }
        else
        {
            var rnd = UnityEngine.Random.Range(0f, 100f);

            //if (rnd > 50f)
            //{
            //    _animationController.Hit();
            //}
            //else
            //{
                _animationController.HitVisual();
            //}
        }

        OnHealthChanged?.Invoke(_currentHealth);
        _healthManaService?.UpdateHealth(_currentHealth, _health);
    }

    public float GetMaxHealth() => _health;
    public float GetCurrentHealth() => _currentHealth;
}
