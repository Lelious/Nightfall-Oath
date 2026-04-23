using UnityEngine;

public class Arrow : MonoBehaviour
{
    [SerializeField] private float _arrowSpeed = 3f;
    [SerializeField] private GameObject _hitImpact;

    private bool _isAppliedDamage;

    private void Awake()
    {
        Destroy(gameObject, 5f);
    }

    private void FixedUpdate()
    {
        transform.position += transform.forward * _arrowSpeed * Time.fixedDeltaTime;
    }

    private void OnTriggerEnter(Collider other)
    {
        if(other.TryGetComponent(out HealthComponent health) && !_isAppliedDamage)
        {
            _isAppliedDamage = true;
            health.TakeDamage(Random.Range(20f, 80f));
            var impact = Instantiate(_hitImpact, new Vector3(other.transform.position.x, other.transform.position.y + 1.3f, other.transform.position.z), other.transform.rotation);
            Destroy(gameObject);
        }
    }
}
