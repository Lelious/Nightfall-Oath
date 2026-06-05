using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using Zenject;

public class CustomLightService : ITickable, IDisposable
{
    private List<CustomLight> _lightSources = new();
    private PoolService _poolService;
    private const int MAX_LIGHTS = 50;
    private const ushort LIGHT_POOL_ID = 0;
    private Vector4[] lightPositions = new Vector4[MAX_LIGHTS];
    private Vector4[] lightColors = new Vector4[MAX_LIGHTS];
    private float[] lightRadius = new float[MAX_LIGHTS];

    [Inject]
    public void Construct(PoolService poolService)
    {
        _poolService = poolService;
    }

    public void Tick()
    {
        if (_lightSources.Count == 0) return;

        int count = Mathf.Min(_lightSources.Count, MAX_LIGHTS);

        for (int i = 0; i < count; i++)
        {
            if (_lightSources[i] == null) continue;
            var data = _lightSources[i].GetData();

            lightPositions[i] = data;
            lightColors[i] = _lightSources[i].GetColor();
            lightRadius[i] = data.w;
        }

        CommandBuffer cmd = new();
        cmd.SetGlobalInt("_LightCount", _lightSources.Count);
        cmd.SetGlobalVectorArray("_LightPositions", lightPositions);
        cmd.SetGlobalVectorArray("_LightColors", lightColors);
        cmd.SetGlobalFloatArray("_LightRadius", lightRadius);
        Graphics.ExecuteCommandBuffer(cmd);
        cmd.Release();
    }

    public void RegisterLightSource(CustomLight source)
    {
        _lightSources.Add(source);
    }

    public void UnregisterLightSource(CustomLight source)
    {
        _lightSources.Remove(source);
    }

    public void Dispose()
    {
        CommandBuffer cmd = new();
        cmd.SetGlobalInt("_LightCount", 0);
        Graphics.ExecuteCommandBuffer(cmd);
        cmd.Release();
    }
}
