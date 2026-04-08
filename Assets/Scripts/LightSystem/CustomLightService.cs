using System.Collections.Generic;
using TMPro;
using UnityEngine;

public class CustomLightService : MonoBehaviour
{
    [SerializeField] private List<CustomLight> _lightSources = new();
    [SerializeField] private TextMeshProUGUI _fpsText;

    private Queue<int> _fpsQueue = new(30);
    private const int MAX_LIGHTS = 50;

    private Vector4[] lightPositions = new Vector4[MAX_LIGHTS];
    private Vector4[] lightColors = new Vector4[MAX_LIGHTS];
    private float[] lightRadii = new float[MAX_LIGHTS];

    private void Awake()
    {
        for (int i = 0; i < 30; i++)
        {
            _fpsQueue.Enqueue(0);
        }
    }

    private void Update()
    {
        var fps = _fpsQueue.Dequeue();
        var median = 0;

        foreach (var item in _fpsQueue)
        {
            median += item;
        } 

        _fpsText.text = $"{(int) median / _fpsQueue.Count}";
        if (_lightSources.Count == 0) return;

        int count = Mathf.Min(_lightSources.Count, MAX_LIGHTS);

        for (int i = 0; i < count; i++)
        {
            var data = _lightSources[i].GetData();

            lightPositions[i] = data;
            lightColors[i] = _lightSources[i].GetColor();
            lightRadii[i] = data.w;
        }

        Shader.SetGlobalInt("_LightCount", _lightSources.Count);
        Shader.SetGlobalVectorArray("_LightPositions", lightPositions);
        Shader.SetGlobalVectorArray("_LightColors", lightColors);
        Shader.SetGlobalFloatArray("_LightRadii", lightRadii);
        _fpsQueue.Enqueue((int)(1f / Time.deltaTime));
    }

    public void RegisterLightSource(CustomLight source)
    {
        _lightSources.Add(source);
    }

    public void UnregisterLightSource(CustomLight source)
    {
        _lightSources.Remove(source);
    }

    private void OnDisable()
    {
        Shader.SetGlobalInt("_LightCount", 0);
    }
}
