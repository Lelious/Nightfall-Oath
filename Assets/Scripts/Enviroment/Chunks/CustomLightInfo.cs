using System;
using UnityEngine;

[Serializable]
public class CustomLightInfo
{
    [ColorUsage(true, true)] public Color Color;
    public ushort Radius;
    public ushort Intensity;
    public bool Flickering;
}