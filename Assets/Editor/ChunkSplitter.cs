using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using System.IO;

public class ChunkSplitter : EditorWindow
{
    int chunkSize = 64;

    [MenuItem("Tools/Mesh Chunk Exporter (Grid Correct)")]
    static void Init()
    {
        GetWindow<ChunkSplitter>();
    }

    void OnGUI()
    {
        chunkSize = EditorGUILayout.IntField("Chunk Size (verts per side)", chunkSize);

        if (GUILayout.Button("Split Selected Mesh"))
        {
            SplitMesh();
        }
    }

    void SplitMesh()
    {
        var go = Selection.activeGameObject;
        if (!go)
        {
            Debug.LogError("Выбери объект");
            return;
        }

        var mf = go.GetComponent<MeshFilter>();
        if (!mf)
        {
            Debug.LogError("Нет MeshFilter");
            return;
        }

        Mesh mesh = mf.sharedMesh;

        var verts = mesh.vertices;
        var uvs = mesh.uv;

        int totalVerts = verts.Length;
        int gridSize = Mathf.RoundToInt(Mathf.Sqrt(totalVerts));

        if (gridSize * gridSize != totalVerts)
        {
            Debug.LogError("Меш не является ровной grid-сеткой");
            return;
        }

        string folder = "Assets/Chunks";
        if (!Directory.Exists(folder))
            Directory.CreateDirectory(folder);

        int chunkIndex = 0;

        for (int cy = 0; cy < gridSize - 1; cy += chunkSize)
        {
            for (int cx = 0; cx < gridSize - 1; cx += chunkSize)
            {
                List<Vector3> cVerts = new List<Vector3>();
                List<Vector2> cUVs = new List<Vector2>();
                List<int> cTris = new List<int>();

                int vertPerLine = chunkSize + 1;

                for (int y = 0; y <= chunkSize; y++)
                {
                    for (int x = 0; x <= chunkSize; x++)
                    {
                        int gx = cx + x;
                        int gy = cy + y;

                        if (gx >= gridSize || gy >= gridSize)
                            continue;

                        int index = gy * gridSize + gx;

                        cVerts.Add(verts[index]);

                        if (uvs != null && uvs.Length > index)
                            cUVs.Add(uvs[index]);
                        else
                            cUVs.Add(Vector2.zero);
                    }
                }

                for (int y = 0; y < chunkSize; y++)
                {
                    for (int x = 0; x < chunkSize; x++)
                    {
                        int i0 = y * vertPerLine + x;
                        int i1 = i0 + 1;
                        int i2 = i0 + vertPerLine;
                        int i3 = i2 + 1;

                        cTris.Add(i0);
                        cTris.Add(i2);
                        cTris.Add(i1);

                        cTris.Add(i2);
                        cTris.Add(i3);
                        cTris.Add(i1);
                    }
                }

                Mesh chunkMesh = new Mesh();
                chunkMesh.indexFormat = UnityEngine.Rendering.IndexFormat.UInt32;

                chunkMesh.vertices = cVerts.ToArray();
                chunkMesh.uv = cUVs.ToArray();
                chunkMesh.triangles = cTris.ToArray();

                chunkMesh.RecalculateNormals();
                chunkMesh.RecalculateBounds();

                string path = $"{folder}/chunk_{chunkIndex}.asset";
                AssetDatabase.CreateAsset(chunkMesh, path);

                chunkIndex++;
            }
        }

        AssetDatabase.SaveAssets();

        Debug.Log($"Готово! Чанков: {chunkIndex}");
    }
}