using UnityEngine;

public class MapCreatureInfo : MapObjectInfo
{
    public byte CreatureType;
    public ushort Level;
    public bool Elite;

    public MapCreatureInfo(ushort id, Vector3 position, Quaternion rotation, Vector3 scale, MapObjectType type, byte creatureType, ushort level, bool elite)
        : base(id, position, rotation, scale, type)
    {
        CreatureType = creatureType;
        Level = level;
        Elite = elite;
    }
}
