using UnityEngine;

[ExecuteAlways]
public class FogService : MonoBehaviour
{
    [Header("Настройки обычной зоны")]
    public Color defaultColor = new Color(0.32f, 0.34f, 0.38f);
    public float defaultStart = 50f;
    public float defaultEnd = 70f;

    [Header("Настройки болота (Ползучий зеленый туман)")]
    public Color swampColor = new Color(0.12f, 0.25f, 0.15f);
    public float swampStart = 15f;
    public float swampEnd = 35f;

    [Header("Скорость перехода между зонами")]
    public float transitionSpeed = 1.5f;

    private static readonly int FogColorId = Shader.PropertyToID("_FogColor");
    private static readonly int FogStartId = Shader.PropertyToID("_FogStart");
    private static readonly int FogEndId = Shader.PropertyToID("_FogEnd");

    private Color _currentColor;
    private float _currentStart;
    private float _currentEnd;

    private Color _targetColor;
    private float _targetStart;
    private float _targetEnd;

    private void Start()
    {
        _currentColor = defaultColor;
        _currentStart = defaultStart;
        _currentEnd = defaultEnd;

        SetTargetPreset(false);
        ApplyFogParameters();
    }

    private void Update()
    {
        float t = Time.deltaTime * transitionSpeed;
        _currentColor = Color.Lerp(_currentColor, _targetColor, t);
        _currentStart = Mathf.Lerp(_currentStart, _targetStart, t);
        _currentEnd = Mathf.Lerp(_currentEnd, _targetEnd, t);

        ApplyFogParameters();
    }

    private void ApplyFogParameters()
    {
        Shader.SetGlobalColor(FogColorId, _currentColor);
        Shader.SetGlobalFloat(FogStartId, _currentStart);
        Shader.SetGlobalFloat(FogEndId, _currentEnd);

        if (Camera.main != null)
        {
            Camera.main.backgroundColor = _currentColor;
        }
    }

    public void SetTargetPreset(bool isSwamp)
    {
        _targetColor = isSwamp ? swampColor : defaultColor;
        _targetStart = isSwamp ? swampStart : defaultStart;
        _targetEnd = isSwamp ? swampEnd : defaultEnd;
    }

    [ContextMenu("Toggle Swamp Mode")]
    private void DebugToggle()
    {
        SetTargetPreset(_targetColor == defaultColor);
    }

    private void OnDestroy()
    {
        Shader.SetGlobalColor(FogColorId, defaultColor);
        Shader.SetGlobalFloat(FogStartId, defaultStart);
        Shader.SetGlobalFloat(FogEndId, defaultEnd);
    }
}
