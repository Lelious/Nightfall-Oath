using UnityEngine;
using Zenject;

public class DamageProcessService
{
    private FloatingTextService _floatingTextService;

    [Inject]
    public void Construct(FloatingTextService floatingTextService)
    {
        _floatingTextService = floatingTextService;
    }

    public void ProcessDamage(HealthComponent target, float value, DamageSource source)
    {
        if(target.IsAlive())
        {
            target.TakeDamage(value);
            _floatingTextService.AddFloatingText(Mathf.RoundToInt(value), target.transform.position, source);
        }
    }
}
