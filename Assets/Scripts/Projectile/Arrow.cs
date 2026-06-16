using UnityEngine;

public class Arrow : MonoBehaviour
{
    [SerializeField] private float _arrowSpeed = 3f;
    [SerializeField] private GameObject _hitImpact;

    private DamageProcessService _damageService;
    private bool _isAppliedDamage;

    private void Awake()
    {
        Destroy(gameObject, 5f);
    }

    private void FixedUpdate()
    {
        transform.position += transform.forward * _arrowSpeed * Time.fixedDeltaTime;
    }

    public void InitializeArrow(DamageProcessService service)
    {
        _damageService = service;
    }

    private void OnTriggerEnter(Collider other)
    {
        if(other.TryGetComponent(out HealthComponent health) && !_isAppliedDamage)
        {
            _isAppliedDamage = true;
            var dmg = Random.Range(20f, 80f);
            var crit = Random.Range(0, 2);
            var damage = crit > 0 ? dmg * 2 : dmg;
            _damageService.ProcessDamage(health, damage, crit > 0 ? DamageSource.Critical : DamageSource.Creature);
            var impact = Instantiate(_hitImpact, new Vector3(other.transform.position.x, other.transform.position.y + 1.3f, other.transform.position.z), other.transform.rotation);
            Destroy(gameObject);
        }
    }
}
