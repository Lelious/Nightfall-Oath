using UnityEngine;

public class CustomLight : MonoBehaviour
{
    [ColorUsage(true, true)][SerializeField] private Color _color;
    [SerializeField] private float _radius;
    [SerializeField] private float _intensity;

    public Vector4 GetData()
    {
        return new Vector4(transform.position.x, transform.position.y, transform.position.z, _radius);
    }

    public Vector4 GetColor()
    {
        Color final = _color * _intensity;
        return new Vector4(final.r, final.g, final.b, 1f);
    }

    private void OnDrawGizmos()
    {
        Gizmos.color = _color;
        Gizmos.DrawWireSphere(transform.position, _radius);
    }

    private void OnEnable()
    {
        FindAnyObjectByType<CustomLightService>().RegisterLightSource(this);
    }

    private void OnDisable()
    {
        FindAnyObjectByType<CustomLightService>().UnregisterLightSource(this);
    }
}
