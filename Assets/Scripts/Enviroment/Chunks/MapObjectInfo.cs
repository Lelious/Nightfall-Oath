using UnityEngine;

public class MapObjectInfo
{
    public ushort Id;
    public Vector3 Position;
    public Quaternion Rotation;
    public Vector3 Scale;
    public IMapObject MapObject;

    public MapObjectInfo(ushort id, Vector3 position, Quaternion rotation, Vector3 scale)
    {
        Id = id;
        Position = position;
        Rotation = rotation;
        Scale = scale;
    }

    public void SetMapObject(IMapObject obj)
    {
        MapObject = obj;
        MapObject.SetPosition(Position);
        MapObject.SetRotation(Rotation);
        MapObject.SetScale(Scale);
    }
}