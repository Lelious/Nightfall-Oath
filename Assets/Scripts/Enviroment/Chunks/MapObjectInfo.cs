using System;
using UnityEngine;

[Serializable]
public class MapObjectInfo
{
    public ushort Id;
    public Vector3 Position;
    public Quaternion Rotation;
    public Vector3 Scale;
    public MapObjectType Type;
    public IMapObject MapObject;
    public bool Initialized;

    public MapObjectInfo(ushort id, Vector3 position, Quaternion rotation, Vector3 scale, MapObjectType type)
    {
        Id = id;
        Position = position;
        Rotation = rotation;
        Scale = scale;
        Type = type;
    }

    public void SetMapObject(IMapObject obj)
    {
        MapObject = obj;
        MapObject.SetPosition(Position);
        MapObject.SetRotation(Rotation);
        MapObject.SetScale(Scale);
    }
}

public enum MapObjectType : byte
{
    StaticDecoration = 0,
    Creature = 1,
    Interactive = 2
}