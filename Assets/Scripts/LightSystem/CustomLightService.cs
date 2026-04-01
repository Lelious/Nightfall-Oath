using System.Collections.Generic;
using UnityEngine;

public class CustomLightService : MonoBehaviour
{
    [SerializeField] private List<CustomLight> _lightSources = new();
    private List<float> lightRadii = new List<float>();
    private Vector4[] lightPositions;
    private Vector4[] lightColors;

    private void Update()
    {
        lightRadii.Clear();

        if (_lightSources.Count == 0) return;
        lightPositions = new Vector4[_lightSources.Count];
        lightColors = new Vector4[_lightSources.Count];

        for (int i = 0; i < _lightSources.Count; i++)
        {
            lightPositions[i] = _lightSources[i].GetData();
            lightColors[i] = _lightSources[i].GetColor();
            lightRadii.Add(lightPositions[i].w);
        }

        Shader.SetGlobalInt("_LightCount", _lightSources.Count);
        Shader.SetGlobalVectorArray("_LightPositions", lightPositions);
        Shader.SetGlobalVectorArray("_LightColors", lightColors);
        Shader.SetGlobalFloatArray("_LightRadii", lightRadii);
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
