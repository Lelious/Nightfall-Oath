using System.Collections.Generic;
using System.IO;
using UnityEngine;

public static class BinaryChunkSerializer
{
    private const float Range = 1000f;
    private const float ScaleMax = 300f;

    public static byte[] Serialize(IMapObject[] objects, Vector3 chunkCenter)
    {
        using (MemoryStream ms = new MemoryStream())
        using (BinaryWriter writer = new BinaryWriter(ms))
        {
            writer.Write(objects.Length);
            foreach (var obj in objects)
            {
                writer.Write(obj.Id());

                Vector3 localPos = obj.Position() - chunkCenter;

                localPos.x += 50f;
                localPos.z += 50f;
                float chunkRange = 100f;

                WriteVector3Ushort(writer, localPos, chunkRange, true);
                WriteRotationEuler(writer, obj.Rotation());
                WriteVector3Ushort(writer, obj.Scale(), ScaleMax, false);
                WriteType(writer, obj.ObjType());

                if (obj.ObjType().Equals(MapObjectType.Creature))
                {
                    var creature = (IMapCreature)obj;
                    var (type, level, elite) = creature.GetCreatureTypeAndLvl();
                    writer.Write(type);
                    writer.Write(level);
                    writer.Write(elite);
                }
            }
            return ms.ToArray();
        }
    }

    public static List<MapObjectInfo> Deserialize(byte[] data, Vector3 chunkCenter)
    {
        var list = new List<MapObjectInfo>();
        using (MemoryStream ms = new MemoryStream(data))
        using (BinaryReader reader = new BinaryReader(ms))
        {
            int count = reader.ReadInt32();
            for (int i = 0; i < count; i++)
            {
                ushort id = reader.ReadUInt16();
                float chunkRange = 100f;
                Vector3 localPos = ReadVector3Ushort(reader, chunkRange, true);

                localPos.x -= 50f;
                localPos.z -= 50f;

                Vector3 globalPos = chunkCenter + localPos;
                Quaternion rot = ReadRotationEuler(reader);
                Vector3 scale = ReadVector3Ushort(reader, ScaleMax, false);
                MapObjectType type = ReadType(reader);

                if (type.Equals(MapObjectType.Creature))
                {
                    byte creatureType = reader.ReadByte();
                    ushort level = reader.ReadUInt16();
                    bool elite = reader.ReadBoolean();

                    list.Add(new MapCreatureInfo(id, globalPos, rot, scale, type, creatureType, level, elite));
                }
                else
                {
                    list.Add(new MapObjectInfo(id, globalPos, rot, scale, type));
                }
            }
        }

        return list;
    }

    private static void WriteVector3Ushort(BinaryWriter w, Vector3 v, float range, bool isPositiveOnly = false)
    {
        float min = isPositiveOnly ? 0f : -range;

        ushort x = (ushort)Mathf.RoundToInt(Mathf.Clamp01(Mathf.InverseLerp(min, range, v.x)) * 65535f);
        ushort y = (ushort)Mathf.RoundToInt(Mathf.Clamp01(Mathf.InverseLerp(min, range, v.y)) * 65535f);
        ushort z = (ushort)Mathf.RoundToInt(Mathf.Clamp01(Mathf.InverseLerp(min, range, v.z)) * 65535f);

        w.Write(x);
        w.Write(y);
        w.Write(z);
    }

    private static Vector3 ReadVector3Ushort(BinaryReader r, float range, bool isPositiveOnly = false)
    {
        float min = isPositiveOnly ? 0f : -range;

        float x = Mathf.Lerp(min, range, r.ReadUInt16() / 65535f);
        float y = Mathf.Lerp(min, range, r.ReadUInt16() / 65535f);
        float z = Mathf.Lerp(min, range, r.ReadUInt16() / 65535f);
        return new Vector3(x, y, z);
    }

    private static void WriteRotationEuler(BinaryWriter w, Quaternion q)
    {
        Vector3 euler = q.eulerAngles;

        ushort x = (ushort)(Mathf.Clamp01(euler.x / 360f) * 65535f);
        ushort y = (ushort)(Mathf.Clamp01(euler.y / 360f) * 65535f);
        ushort z = (ushort)(Mathf.Clamp01(euler.z / 360f) * 65535f);

        w.Write(x);
        w.Write(y);
        w.Write(z);
    }

    private static Quaternion ReadRotationEuler(BinaryReader r)
    {
        float x = (r.ReadUInt16() / 65535f) * 360f;
        float y = (r.ReadUInt16() / 65535f) * 360f;
        float z = (r.ReadUInt16() / 65535f) * 360f;

        return Quaternion.Euler(x, y, z);
    }

    private static MapObjectType ReadType(BinaryReader r)
    {
        return (MapObjectType)r.ReadByte();
    }

    private static void WriteType(BinaryWriter w, MapObjectType type)
    {
        w.Write((byte)type);
    }
}
