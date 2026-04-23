using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.Rendering;

public class CustomLightService : MonoBehaviour
{
    [SerializeField] private List<CustomLight> _lightSources = new();
    [SerializeField] private TextMeshProUGUI _fpsText;
    [SerializeField] private Transform _player;

    private Queue<int> _fpsQueue = new(30);
    private const int MAX_LIGHTS = 50;

    private Vector4[] lightPositions = new Vector4[MAX_LIGHTS];
    private Vector4[] lightColors = new Vector4[MAX_LIGHTS];
    private float[] lightRadii = new float[MAX_LIGHTS];

    private void Start()
    {
        for (int i = 0; i < 30; i++)
        {
            _fpsQueue.Enqueue(0);
        }
    }

    private void LateUpdate()
    {
        _fpsQueue.Dequeue();

        var median = 0;

        foreach (var item in _fpsQueue)
        {
            median += item;
        }

        _fpsText.text = $"{(int)median / _fpsQueue.Count}";
        if (_lightSources.Count == 0) return;

        int count = Mathf.Min(_lightSources.Count, MAX_LIGHTS);

        for (int i = 0; i < count; i++)
        {
            if (_lightSources[i] == null) continue;
            var data = _lightSources[i].GetData();

            lightPositions[i] = data;
            lightColors[i] = _lightSources[i].GetColor();
            lightRadii[i] = data.w;
        }
        CommandBuffer cmd = new();
        cmd.SetGlobalInt("_LightCount", _lightSources.Count);
        cmd.SetGlobalVectorArray("_LightPositions", lightPositions);
        cmd.SetGlobalVectorArray("_LightColors", lightColors);
        cmd.SetGlobalFloatArray("_LightRadii", lightRadii);
        Graphics.ExecuteCommandBuffer(cmd);
        cmd.Release();
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
        CommandBuffer cmd = new();
        cmd.SetGlobalInt("_LightCount", 0);
        Graphics.ExecuteCommandBuffer(cmd);
        cmd.Release();
    }
}
