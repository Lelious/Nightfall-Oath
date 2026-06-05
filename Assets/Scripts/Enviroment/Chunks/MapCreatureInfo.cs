using UnityEngine;

public class MapCreatureInfo : MapObjectInfo
{
    public byte CreatureType;
    public ushort Level;
    public bool Elite;

    public MapCreatureInfo(ushort id, Vector3 position, Quaternion rotation, Vector3 scale, byte creatureType, ushort level, bool elite)
        : base(id, position, rotation, scale)
    {
        CreatureType = creatureType;
        Level = level;
        Elite = elite;
    }
}
