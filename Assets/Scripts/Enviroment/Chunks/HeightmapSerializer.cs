using UnityEngine;
using System.IO;
using Unity.Collections;

public static class HeightmapSerializer
{
    public static void Save(string path, ushort[,] data)
    {
        int w = data.GetLength(0);
        int h = data.GetLength(1);

        using (BinaryWriter writer = new BinaryWriter(File.Open(path, FileMode.Create)))
        {
            writer.Write(w);
            writer.Write(h);

            for (int y = 0; y < h; y++)
            {
                for (int x = 0; x < w; x++)
                {
                    writer.Write(data[x, y]);
                }
            }
        }
    }

    public static NativeArray<ushort> Load(byte[] data)
    {       
        using (MemoryStream ms = new MemoryStream(data))
        using (BinaryReader reader = new BinaryReader(ms))
        {
            int w = reader.ReadInt32();
            int h = reader.ReadInt32();

            var result = new NativeArray<ushort>(
            w * h,
            Allocator.Persistent
        );

            for (int y = 0; y < h; y++)
            {
                for (int x = 0; x < w; x++)
                {
                    result[x + y * w] = reader.ReadUInt16();
                }
            }

            return result;
        }
    }
}
