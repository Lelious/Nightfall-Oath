using UnityEngine;
using Zenject;

public class CustomLight : MonoBehaviour
{
    [ColorUsage(true, true)][SerializeField] private Color _color;
    [SerializeField] private float _radius;
    [SerializeField] private float _intensity;
    [SerializeField] private float _flickerSpeed = 8.0f;
    [SerializeField] private bool _flickering;

    private CustomLightService _lightService;
    private float _finalIntensity;

    public void LateUpdate()
    {
        if (_flickering)
        {
            float noise = Mathf.Sin(Time.timeSinceLevelLoad * _flickerSpeed) * Mathf.Cos(Time.timeSinceLevelLoad * _flickerSpeed * 0.7f);

            float modifier = Mathf.Lerp(0.7f, 1.0f, (noise + 1f) * 0.5f);

            _finalIntensity = _intensity * modifier;
        }
        else
        {
            _finalIntensity = _intensity;
        }
    }

    [Inject]
    public void Construct(CustomLightService lightService)
    {
        _lightService = lightService;
        _finalIntensity = _intensity;
    }

    public Vector4 GetData()
    {
        return new Vector4(transform.position.x, transform.position.y, transform.position.z, _radius);
    }

    public Vector4 GetColor()
    {       
        Color final = _color * _finalIntensity;
        return new Vector4(final.r, final.g, final.b, 1);
    }

    public float GetIntensity() => _finalIntensity;

    public void SetData(Vector4 data)
    {
        _radius = data.x;
        _intensity = data.y;
        _flickerSpeed = data.z;
        _flickering = data.w > 0.1f ? true : false; 
    }
    public void SetColor(Color color)
    {
        _color = color;
    }

    private void OnDrawGizmos()
    {
        Gizmos.color = _color;
        Gizmos.DrawWireSphere(transform.position, _radius);
    }

    private void OnEnable()
    {
        _lightService.RegisterLightSource(this);
    }

    private void OnDisable()
    {
        _lightService.UnregisterLightSource(this);
    }
}
