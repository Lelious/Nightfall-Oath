using System;
using UnityEngine;
using UnityEngine.Rendering;
using Zenject;

public class CustomLightService : IInitializable, ITickable, IDisposable
{
    private const int MAX_LIGHTS = 50;
    private readonly CustomLight[] _lightSources = new CustomLight[MAX_LIGHTS];

    private readonly System.Collections.Generic.List<Vector4> _lightPositions = new(MAX_LIGHTS);
    private readonly System.Collections.Generic.List<Vector4> _lightColors = new(MAX_LIGHTS);
    private readonly System.Collections.Generic.List<float> _lightRadius = new(MAX_LIGHTS);

    private CommandBuffer _cmd;
    private int count;

    public void Initialize()
    {
        _cmd = new CommandBuffer { name = "CustomLightingUpdate" };

        for (int i = 0; i < MAX_LIGHTS; i++)
        {
            _lightPositions.Add(Vector4.zero);
            _lightColors.Add(Vector4.zero);
            _lightRadius.Add(0f);
        }
    }

    public void Tick()
    {
        if (count == 0)
        {
            _cmd.Clear();
            _cmd.SetGlobalInt("_LightCount", 0);
            Graphics.ExecuteCommandBuffer(_cmd);
            return;
        }

        for (int i = 0; i < count; i++)
        {
            Vector4 data = _lightSources[i].GetData();

            _lightPositions[i] = data;
            _lightColors[i] = _lightSources[i].GetColor();
            _lightRadius[i] = data.w;
        }

        _cmd.Clear();
        _cmd.SetGlobalInt("_LightCount", count);

        _cmd.SetGlobalVectorArray("_LightPositions", _lightPositions);
        _cmd.SetGlobalVectorArray("_LightColors", _lightColors);
        _cmd.SetGlobalFloatArray("_LightRadius", _lightRadius);

        Graphics.ExecuteCommandBuffer(_cmd);
    }

    public void RegisterLightSource(CustomLight source)
    {
        if (count >= MAX_LIGHTS) return;

        _lightSources[count] = source;
        count++;
    }

    public void UnregisterLightSource(CustomLight source)
    {
        for (int i = 0; i < count; i++)
        {
            if (_lightSources[i] == source)
            {
                _lightSources[i] = _lightSources[count - 1];
                _lightSources[count - 1] = null;
                count--;
                break;
            }
        }
    }

    public void Dispose()
    {
        if (_cmd != null)
        {
            _cmd.Clear();
            _cmd.SetGlobalInt("_LightCount", 0);
            Graphics.ExecuteCommandBuffer(_cmd);

            _cmd.Release();
            _cmd = null;
        }
    }
}
